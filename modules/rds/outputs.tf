output "db_secret_arn" {
  value       = aws_secretsmanager_secret.db_secret.arn
  description = "ARN of the database secret"
}

output "db_endpoint" {
  value       = aws_db_instance.lamp_db.endpoint
  description = "RDS endpoint"
}