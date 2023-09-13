### SPOKE VM INSTANCES ####
data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "name"
    values = ["bitnami-nginx-1.21*-linux-debian-10-x86_64-hvm-ebs-nami"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  owners = ["979382823631"] # bitnami = 979382823631
}


data "aws_ebs_default_kms_key" "current" {
}

data "aws_kms_alias" "current_arn" {
  name = data.aws_ebs_default_kms_key.current.key_arn
}

resource "aws_iam_role" "spoke_vm_ec2_iam_role" {
  name               = "${var.name_prefix}spoke_vm"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"}
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "spoke_vm_iam_instance_profile" {

  name = "${var.name_prefix}spoke_vm_instance_profile"
  role = aws_iam_role.spoke_vm_ec2_iam_role.name
}

data "aws_caller_identity" "current" {}

locals {
  default_eni_subnets = [for i in var.interfaces : i.subnet_info if i.device_index == 0][0]
  default_eni_sg_ids  = flatten([for i in var.interfaces : i.security_group_ids if i.device_index == 0])
  default_eni_public_ip = flatten([for i in var.interfaces : i.create_public_ip if i.device_index == 0])
  account_id = data.aws_caller_identity.current.account_id

  # Extracting subnet id based on availability zone
  subnet_id_based_on_az = {for s in local.default_eni_subnets : s.availability_zone => s.subnet_id}
}

output "debug_default_eni_subnets" {
  value = local.default_eni_subnets
}



# Create launch template with a single interface
resource "aws_launch_template" "this" {
  name          = "${var.name_prefix}template"
  ebs_optimized = false
  image_id      = "ami-02f2eac28b289d426"
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  tags          = var.global_tags
  #user_data = base64encode(var.bootstrapoptions)

  monitoring {
    enabled = true  # Enables detailed CloudWatch monitoring
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.spoke_vm_iam_instance_profile.name
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record = true
  }
  network_interfaces {
    device_index                = 0
    security_groups             = [local.default_eni_sg_ids[0]]
    #subnet_id                   = values(local.default_eni_subnet_names[0])[0]
    #subnet_id = local.default_eni_subnets[0].subnet_id
    #associate_public_ip_address = try(local.default_eni_public_ip[0])
    delete_on_termination = true

  }

  /*
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      delete_on_termination = true
      kms_key_id            = data.aws_kms_alias.current_arn.target_key_arn
      encrypted             = true
      volume_size = 8
    }
  }
  */
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}nginixvm"
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"
    instance_metadata_tags      = "enabled"
  }
}

# Create autoscaling group based on launch template and ALL subnets from var.interfaces
resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}${var.asg_name}"
  #vpc_zone_identifier = distinct([for k, v in local.default_eni_subnet_names[0] : v])
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  target_group_arns   = var.target_group_arns


  # Use the launch template
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }


  dynamic "tag" {
    for_each = var.global_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  initial_lifecycle_hook {
    name                 = "${var.name_prefix}asg-launch-hook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = var.lifecycle_hook_timeout
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  initial_lifecycle_hook {
    name                 = "${var.name_prefix}asg-terminate-hook"
    default_result       = "CONTINUE"
    heartbeat_timeout    = var.lifecycle_hook_timeout
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }
  health_check_type         = "ELB"
  health_check_grace_period = 300  # adjust as needed

  suspended_processes = var.suspended_processes

  depends_on = [
    #aws_cloudwatch_event_target.instance_launch_event,
    #aws_cloudwatch_event_target.instance_terminate_event
  ]
}

resource "aws_autoscalingplans_scaling_plan" "this" {
  count = var.scaling_plan_enabled ? 1 : 0
  name  = "${var.name_prefix}scaling-plan"
  application_source {
    dynamic "tag_filter" {
      for_each = var.scaling_tags
      content {
        key    = tag_filter.value.key
        values = [tag_filter.value.value]  # Wrap the value inside a list
      }
    }
  }

  scaling_instruction {
    max_capacity       = var.max_size
    min_capacity       = var.min_size
    resource_id        = format("autoScalingGroup/%s", aws_autoscaling_group.this.name)
    scalable_dimension = "autoscaling:autoScalingGroup:DesiredCapacity"
    service_namespace  = "autoscaling"
    target_tracking_configuration {
      customized_scaling_metric_specification {
        metric_name = var.scaling_metric_name
        namespace   = var.scaling_cloudwatch_namespace
        statistic   = var.scaling_statistic
      }
      target_value = var.scaling_target_value
      #scale_out_cooldown = 15
    }
  }
}

