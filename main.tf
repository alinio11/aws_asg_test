

### AUTOSCALING GROUP WITH VM-Series INSTANCES ###

module "my_asg" {
  source = "./modules/asg"

  # Pass in any required variables for the module
  region = var.region
  name_prefix = var.name_prefix
  ssh_key_name = var.ssh_key_name
  #ami_id                = module.my_asg.ami_id
  instance_type         = var.instance_type
  interfaces            = var.interfaces
  subnet_ids = var.subnet_ids
  vpc_id                = var.vpc_id
  #user_data             = var.bootstrap_options
  asg_name              = var.asg_name
  desired_capacity      = var.desired_capacity
  min_size              = var.min_size
  max_size              = var.max_size
  target_group_arns      = var.target_group_arns
  lifecycle_hook_timeout = var.lifecycle_hook_timeout
  suspended_processes   = var.suspended_processes
  global_tags           = var.global_tags
  scaling_cloudwatch_namespace = var.cloudwatch_namespace
  scaling_plan_enabled = var.scaling_plan_enabled
}

output "debug" {
  value = module.my_asg.debug_default_eni_subnets
}