resource "aws_cloudwatch_dashboard" "lamp_dashboard" {
  dashboard_name = "${var.project_name}-dashboard"
  
  depends_on = [
    aws_cloudwatch_log_group.php_app_visits,
    aws_cloudwatch_log_group.php_app_errors  
  ]

  dashboard_body = jsonencode({
    widgets = [
      # CPU Utilization
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          title = "EC2 CPU Utilization",
          metrics = [
            [ "CWAgent", "cpu_usage_idle", "InstanceId", "*" ]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region
        }
      },

      # Memory Usage
      {
        type = "metric",
        x    = 12,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          title = "Memory Usage (%)",
          metrics = [
            [ "CWAgent", "mem_used_percent", "InstanceId", "*" ]
          ],
          period = 300,
          stat   = "Average",
          region = var.aws_region
        }
      },

      # Apache Access Logs
      {
        type = "log",
        x    = 0,
        y    = 6,
        width = 24,
        height = 6,
        properties = {
          title         = "Apache Access Logs",
          query         = "SOURCE '/${var.project_name}/apache-access' | fields @timestamp, @message | sort @timestamp desc | limit 20",
          region        = var.aws_region,
          view          = "table"
        }
      },

      # Apache Error Logs
      {
        type = "log",
        x    = 0,
        y    = 12,
        width = 24,
        height = 6,
        properties = {
          title         = "Apache Error Logs",
          query         = "SOURCE '/${var.project_name}/apache-error' | fields @timestamp, @message | sort @timestamp desc | limit 20",
          region        = var.aws_region,
          view          = "table"
        }
      },

      # System Messages
      {
        type = "log",
        x    = 0,
        y    = 18,
        width = 24,
        height = 6,
        properties = {
          title         = "System Messages (/var/log/messages)",
          query         = "SOURCE '/${var.project_name}/system-messages' | fields @timestamp, @message | sort @timestamp desc | limit 20",
          region        = var.aws_region,
          view          = "table"
        }
      },

      # PHP App Visits Log
      {
        type = "log",
        x    = 0,
        y    = 24,
        width = 24,
        height = 6,
        properties = {
            title  = "PHP App Visits Log",
            query  = "SOURCE '/${var.project_name}/php-app-visits' | fields @timestamp, @message | sort @timestamp desc | limit 20",
            region = var.aws_region,
            view   = "table"
        }
      },

      # PHP App Errors Log
      {
        type = "log",
        x    = 0,
        y    = 30,
        width = 24,
        height = 6,
        properties = {
            title  = "PHP App Errors Log",
            query  = "SOURCE '/${var.project_name}/php-app-errors' | fields @timestamp, @message | sort @timestamp desc | limit 20",
            region = var.aws_region,
            view   = "table"
        }
      }
    ]
  })
}

