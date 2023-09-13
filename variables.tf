
variable "region" {
  description = "AWS region"
  type        = string
  default = "eu-west-2"
}


variable "name_prefix" {
  description = "All resource names will be prepended with this string"
  type        = string
  default = "nlb-netsec"
}

variable "asg_name" {
  description = "Name of the autoscaling group to create"
  type        = string
  default     = "asg-vm-nginix"
}


variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
  default = "Spoke-Bastion-Key"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}
variable "bootstrap_options" {
  description = "Bootstrap options to put into userdata"
  type        = any
  default     = {}
}

variable "interfaces" {
  description = "Network interface configurations for instances"
  type = list(object({
    device_index       = number                 # e.g., 0 for the default interface
    subnet_info        = list(object({          # List of maps containing subnet info
      subnet_id        = string                 # Subnet ID
      availability_zone = string                # Availability zone for the subnet
    }))
    security_group_ids = list(string)           # List of security group IDs for the interface
    create_public_ip   = bool                   # Whether to create a public IP for the interface
  }))
  default = [
   {
      device_index = 0,
      subnet_info = [
        {
          subnet_id = "subnet-00e01e66006c40600",
          availability_zone = "eu-west-2a"
        },
        {
          subnet_id = "subnet-05fa4132b25ed9cdd",
          availability_zone = "eu-west-2b"
        }
      ],
      security_group_ids = ["sg-0389316eb856bf138"],
      create_public_ip = false
    }
  ]

}


variable "target_group_arns" {
  description = "ARNs of target groups (type instance) for the load balancer, which are used by ASG to register VM-Series instances"
  type        = list(string)
  default     = ["arn:aws:elasticloadbalancing:eu-west-2:998386784275:targetgroup/nlb-testapp1-nlb-HTTP-traffic/691411989142dc25"]
}

variable "ip_target_groups" {
  description = "Target groups (type IP) for load balancers, which are used by Lamda to register VM-Series IP of untrust interface"
  type = list(object({
    arn  = string
    port = string
  }))
  default = []
}

variable "lifecycle_hook_timeout" {
  description = "How long should we wait for lambda to finish"
  type        = number
  default     = 300
}

variable "desired_capacity" {
  description = "Number of Amazon EC2 instances that should be running in the group."
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group."
  type        = number
  default     = 4
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group."
  type        = number
  default     = 0
}

variable "suspended_processes" {
  description = "List of processes to suspend for the Auto Scaling Group. The allowed values are Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer, InstanceRefresh"
  type        = list(string)
  default     = []
}

variable "global_tags" {
  description = "Map of AWS tags to apply to all the created resources."
  type        = map(any)
  default = {
    ManagedBy   = "terraform"
   Application = "NLB Test"
   Owner       = "NETSEC"
  }
}


variable "bootstrapoptions" {
  description = "User data to be used for instances"
  type        = string
  default     = "#!/bin/bash\necho 'Hello, World!'"
}


variable "ebs_kms_id" {
  description = "Alias for AWS KMS used for EBS encryption in VM-Series"
  type        = string
  default     = "alias/aws/ebs"
}


variable "scaling_plan_enabled" {
  description = "True, if automatic dynamic scaling policy should be created"
  type        = bool
  default     = true
}

variable "scaling_metric_name" {
  description = "Name of the CloudWatch metric for scaling"
  type        = string
  default     = "CPUUtilization"
}

variable "scaling_tags" {
  description = "Tags used for identifying resources in the scaling plan"
  type = list(object({
    key   = string
    value = string
  }))
  default = [
    {
      key   = "Environment",
      value = "Production"
    },
    {
      key   = "Application",
      value = "WebApp"
    }
  ]
}




variable "scaling_target_value" {
  description = "Target value for the metric used in dynamic scaling policy"
  type        = number
  default     = 70
}

variable "scaling_statistic" {
  description = "Statistic of the metric. Valid values: Average, Maximum, Minimum, SampleCount, Sum"
  default     = "Average"
  type        = string
}

variable "cloudwatch_namespace" {
  type = string
  default     = "AWS/EC2"
}

variable "vpc_id" {
  type = string
  default = "vpc-0cd33b1a570c65cd9"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
  default     = ["subnet-00e01e66006c40600", "subnet-05fa4132b25ed9cdd"]  # Or provide some default subnet IDs
}
