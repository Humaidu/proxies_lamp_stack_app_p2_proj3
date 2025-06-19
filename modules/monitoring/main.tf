
# Create a basic CPU utilization alarm
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Triggers when CPU exceeds 75%"
  actions_enabled     = false  # Set to true and configure SNS for real alerts
  dimensions = {
    AutoScalingGroupName = var.aws_autoscaling_group
  }
}

resource "aws_cloudwatch_log_group" "php_app_visits" {
  name              = "/lamp-stack-app/php-app-visits"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "php_app_errors" {
  name              = "/lamp-stack-app/php-app-errors"
  retention_in_days = 7
}
