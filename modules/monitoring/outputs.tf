# Output to be used in launch template
output "instance_profile_name" {
  value = aws_iam_instance_profile.cw_instance_profile.name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.lamp_dashboard.dashboard_name
}

output "cloudwatch_log_groups" {
  description = "CloudWatch Log Groups created or used by the agent"
  value = [
    "/${var.project_name}/apache-access",
    "/${var.project_name}/apache-error",
    "/${var.project_name}/system-messages"
  ]
}
