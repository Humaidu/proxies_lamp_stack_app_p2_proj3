variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "lampdb"
}

variable "project_name" {
  description = "Project name used in logs and metric namespaces"
  type        = string
}
