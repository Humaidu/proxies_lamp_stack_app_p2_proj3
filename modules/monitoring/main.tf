# Create an IAM role for EC2 to allow publishing logs and metrics to CloudWatch
resource "aws_iam_role" "cw_agent_role" {
  name = "lamp-cw-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AWS-managed policy to allow CloudWatch agent to function
resource "aws_iam_role_policy_attachment" "cw_logs_attach" {
  role       = aws_iam_role.cw_agent_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy to create log groups and streams
resource "aws_iam_policy" "cloudwatch_create_logs" {
  name = "lamp-cloudwatch-create-logs"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

# Create an instance profile to attach the IAM role to EC2
resource "aws_iam_instance_profile" "cw_instance_profile" {
  name = "lamp-cw-instance-profile"
  role = aws_iam_role.cw_agent_role.name
}

# Extra: Attach same policy to the currently used instance role (lamp-ec2-role)
resource "aws_iam_role_policy_attachment" "attach_to_existing_ec2_role" {
  role       = "lamp-ec2-role"  
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

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
    AutoScalingGroupName = var.autoscaling_group_name
  }
}
