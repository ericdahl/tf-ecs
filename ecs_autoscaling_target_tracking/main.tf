

resource "aws_autoscaling_policy" "memory_reservation" {
  name                   = "ecs_autoscaling_memory"
  autoscaling_group_name = "${var.asg_name}"

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = "${var.cluster_name}"
      }

      metric_name = "MemoryReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }

    target_value = "${var.memory_reservation_target}"
  }
}



resource "aws_autoscaling_policy" "cpu_reservation" {
  name                   = "ecs_autoscaling_cpu"
  autoscaling_group_name = "${var.asg_name}"

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_dimension {
        name  = "ClusterName"
        value = "${var.cluster_name}"
      }

      metric_name = "CPUReservation"
      namespace   = "AWS/ECS"
      statistic   = "Average"
    }

    target_value = "${var.cpu_reservation_target}"
  }
}

