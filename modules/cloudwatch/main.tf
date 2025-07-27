resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment}-logs"
  retention_in_days = 30
}

resource "aws_cloudwatch_metric_alarm" "ecs_high_cpu" {
  alarm_name          = "${var.environment}-ecs-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alert when ECS CPU > 75%"
  dimensions = {
    ClusterName = var.ecs_cluster_name
  }
  alarm_actions = [var.sns_topic_arn]
}
