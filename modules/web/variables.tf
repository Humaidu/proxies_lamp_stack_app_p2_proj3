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