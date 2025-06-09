variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "lamp_db"
}