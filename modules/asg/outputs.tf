output "asg" {
  value = aws_autoscaling_group.this
}

output "ami_id" {
  value = data.aws_ami.this.id
}