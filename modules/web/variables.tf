variable "vpc_id" {
  description = "VPC ID where resources will be deployed"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "db_secret_arn" {
  description = "ARN of the database secret"
  type        = string
}

variable "db_endpoint" {
  description = "RDS endpoint"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "project_name" {
  description = "Project name used in logs and metric namespaces"
  type        = string
  default = "lamp-stack-app"
}

variable "instance_profile_name" {
  description = "Instance profile name for EC2"
  type        = string
}
