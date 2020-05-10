resource "aws_sns_topic" "scale_event" {
  name = var.cluster_name}_autoscale_event"
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name = var.cluster_name}_memory_high"

  namespace   = "AWS/ECS"
  metric_name = "MemoryReservation"

  dimensions {
    ClusterName = var.cluster_name
  }

  statistic           = "Average"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 60
  evaluation_periods  = 1
  period              = 60

  alarm_actions = [var.scale_up_actions, aws_sns_topic.scale_event.arn]
}

resource "aws_cloudwatch_metric_alarm" "memory_low" {
  alarm_name = var.cluster_name}_memory_low"

  namespace   = "AWS/ECS"
  metric_name = "MemoryReservation"

  dimensions {
    ClusterName = var.cluster_name
  }

  statistic           = "Average"
  comparison_operator = "LessThanThreshold"
  threshold           = 30
  evaluation_periods  = 1
  period              = 60

  alarm_actions = [var.scale_down_actions, aws_sns_topic.scale_event.arn]
}
