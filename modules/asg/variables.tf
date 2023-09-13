variable "vmseries_version" {
  description = "Select which FW version to deploy"
  default     = "10.2.2"
}

variable "region" {
  description = "AWS region"
  type        = string
}


variable "name_prefix" {
  description = "All resource names will be prepended with this string"
  type        = string
}

variable "asg_name" {
  description = "Name of the autoscaling group to create"
  type        = string
  default     = "asg"
}

variable "ssh_key_name" {
  description = "Name of AWS keypair to associate with instances"
  type        = string
}

variable "instance_type" {
  type = string
}

variable "bootstrapoptions" {
  type =any
  default = "#!/bin/bash\necho 'Hello, World!'"
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
  default = []
}



variable "target_group_arns" {
  description = "ARNs of target groups (type instance) for the load balancer, which are used by ASG to register VM-Series instances"
  type        = list(string)
  default     = []
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

}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group."
  type        = number

}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group."
  type        = number

}

variable "suspended_processes" {
  description = "List of processes to suspend for the Auto Scaling Group. The allowed values are Launch, Terminate, HealthCheck, ReplaceUnhealthy, AZRebalance, AlarmNotification, ScheduledActions, AddToLoadBalancer, InstanceRefresh"
  type        = list(string)
  default     = []
}

variable "global_tags" {
  description = "Map of AWS tags to apply to all the created resources."
  type        = map(any)
}

variable "lambda_timeout" {
  description = "Amount of time Lambda Function has to run in seconds."
  type        = number
  default     = 30
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent execussions for lambda function."
  default     = 100
  type        = number
}


variable "security_group_ids" {
  description = "List of security group IDs associated with the Lambda function"
  type        = list(string)
  default     = []
}



variable "ebs_kms_id" {
  description = "Alias for AWS KMS used for EBS encryption in VM-Series"
  type        = string
  default     = "alias/aws/ebs"
}


variable "scaling_plan_enabled" {
  description = "True, if automatic dynamic scaling policy should be created"
  type        = bool
  default     = false
}

variable "scaling_metric_name" {
  description = "Name of the metric used in dynamic scaling policy"
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
  default     = "Sum"
  type        = string
}


variable "scaling_cloudwatch_namespace" {
  type = string
  default     = "AWS/EC2"
}

variable "vpc_id" {
  type = string

}

variable "subnet_ids" {
  description = "List of subnet IDs for the Auto Scaling Group"
  type        = list(string)
  default     = []  # Or provide some default subnet IDs
}
