data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.app_name}"
  retention_in_days = 7

  tags = {
    App = var.app_name
    VPC = var.vpc_id
  }
}

resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"

  tags = {
    App = var.app_name
  }
}

resource "aws_cloudwatch_dashboard" "app" {
  dashboard_name = "${var.app_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "log"
        properties = {
          region     = data.aws_region.current.name
          logGroupNames = [aws_cloudwatch_log_group.app.name]
          title      = "${var.app_name} Logs"
        }
      }
    ]
  })

  tags = {
    App = var.app_name
  }
}
