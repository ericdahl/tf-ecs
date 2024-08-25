resource "aws_ecs_task_definition" "httpbin" {
  count = var.enable_ec2_httpbin ? 1 : 0

  family = "httpbin"

  container_definitions = templatefile("templates/tasks/httpbin.json", {
    delay_start_connect : 0
  })
}

resource "aws_ecs_service" "httpbin" {
  count = var.enable_ec2_httpbin ? 1 : 0

  cluster         = aws_ecs_cluster.default.name
  name            = "tf-cluster-httpbin"
  task_definition = aws_ecs_task_definition.httpbin[0].arn
  desired_count   = 7

  #  launch_type = "EC2"

  #  capacity_provider_strategy {
  #    capacity_provider = aws_ecs_capacity_provider.default.name
  #    weight = 100
  #  }
  #  force_new_deployment = true

  #  deployment_circuit_breaker {
  #    enable   = true
  #    rollback = true
  #  }
  #
  #  enable_ecs_managed_tags = "true"
  #  propagate_tags          = "SERVICE"
  #  tags = {
  #    ServiceName = "tf-cluster-httpbin"
  #    ClusterName = "tf-cluster"
  #  }
  #
  #  # to avoid possible race condition error on creation
  ##  depends_on = [aws_alb.ecs_service_httpbin]
  #
  #  ordered_placement_strategy {
  #    type  = "spread"
  #    field = "attribute:ecs.availability-zone"
  #  }
  #
  #  ordered_placement_strategy {
  #    type  = "spread"
  #    field = "instanceId"
  #  }

  #  load_balancer {
  #    target_group_arn = aws_alb_target_group.default[0].arn
  #    container_name   = "httpbin"
  #    container_port   = 8080
  #  }

  // Note: As of May 2018, this will stop a task from being
  // killed on startup, but the ALB UnHealthyHost metric is
  // still recorded
  #  health_check_grace_period_seconds = 300

  lifecycle {
    ignore_changes = [
      desired_count,
      capacity_provider_strategy
    ]
  }
}

#resource "aws_alb" "ecs_service_httpbin" {
#  count = var.enable_ec2_httpbin ? 1 : 0
#
#  name = "httpbin-ec2"
#
#  subnets = [
#    module.vpc.subnet_public1,
#    module.vpc.subnet_public2,
#    module.vpc.subnet_public3,
#  ]
#
#  security_groups = [
#    module.vpc.sg_allow_egress,
#    module.vpc.sg_allow_80,
#  ]
#}
#
#resource "aws_alb_listener" "default" {
#  count = var.enable_ec2_httpbin ? 1 : 0
#
#  default_action {
#    target_group_arn = aws_alb_target_group.default[0].arn
#    type             = "forward"
#  }
#
#  load_balancer_arn = aws_alb.ecs_service_httpbin[0].arn
#  port              = 80
#}
#
#resource "aws_alb_target_group" "default" {
#  count = var.enable_ec2_httpbin ? 1 : 0
#
#  name                 = "httpbin-ec2"
#  vpc_id               = module.vpc.vpc_id
#  port                 = 8080
#  protocol             = "HTTP"
#  deregistration_delay = 5
#
#  health_check {
#    # The service task needs to start up and respond to health probes in  #  # unhealthy_threshold * (interval + [0, timeout])  #  # If the probes can't connect to the target then it's immediately recorded  # as a failed health check. This would happen if the target is initializing and  # hasn't started listening on the socket.  #  # e.g.,  #   timeout = 2, unhealthy_threshold = 3, interval = 5  # The target has between 15 and 21 seconds to respond to health checks depending  # on whether it's accepting connections.  #  # This does not seem to be exact. When using a task that takes a constant 30 seconds  # to accept connections, even some tasks managed to get through the health check after  # 20+ repeated failed attempts with 2/3/5.
#
#    healthy_threshold   = 2
#    unhealthy_threshold = 10
#    interval            = 5
#    timeout             = 2
#  }
#}
#
#resource "aws_appautoscaling_target" "ecs_service_httpbin" {
#  count = var.enable_ec2_httpbin ? 1 : 0
#
#  max_capacity       = var.ec2_httpbin_max_capacity
#  min_capacity       = var.ec2_httpbin_min_capacity
#  resource_id        = "service/${aws_ecs_cluster.default.name}/${aws_ecs_service.httpbin[0].name}"
#  role_arn           = data.aws_iam_role.autoscaling.arn
#  scalable_dimension = "ecs:service:DesiredCount"
#  service_namespace  = "ecs"
#}
#
#resource "aws_appautoscaling_policy" "ecs_service_httpbin_target_tracking" {
#  count = var.enable_ec2_httpbin ? 1 : 0
#
#  name               = "ecs_service_httpbin_target_tracking"
#  policy_type        = "TargetTrackingScaling"
#  resource_id        = aws_appautoscaling_target.ecs_service_httpbin[0].resource_id
#  scalable_dimension = aws_appautoscaling_target.ecs_service_httpbin[0].scalable_dimension
#  service_namespace  = aws_appautoscaling_target.ecs_service_httpbin[0].service_namespace
#
#  target_tracking_scaling_policy_configuration {
#    target_value = 30
#
#    predefined_metric_specification {
#      predefined_metric_type = "ALBRequestCountPerTarget"
#      resource_label         = "${aws_alb.ecs_service_httpbin[0].arn_suffix}/${aws_alb_target_group.default[0].arn_suffix}"
#    }
#  }
#
#  depends_on = [aws_appautoscaling_target.ecs_service_httpbin]
#}

