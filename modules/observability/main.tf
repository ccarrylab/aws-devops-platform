resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ecs/${var.app_name}"
  retention_in_days = 30
}

resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

