# Project label (e.g., "lampstack")
variable "project_name" {
  type        = string
  description = "Project or service name used for labeling resources"
  default = "lamp-stack-app"
}

# The name of the Auto Scaling Group for alarms
variable "aws_autoscaling_group" {
  type        = string
  description = "Auto Scaling Group name for metrics/alarms"
}

variable "aws_region" {
  type        = string
  description = "Project or service name used for labeling resources"
  default = "eu-west-1"
}
