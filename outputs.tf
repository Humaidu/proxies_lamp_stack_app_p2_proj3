output "alb_dns_name" {
  value = module.web.alb_dns_name
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
  description = "ARN of the database secret"
  sensitive = true
}

output "db_endpoint" {
  value = module.rds.db_endpoint
  description = "RDS endpoint"
  sensitive = true
}