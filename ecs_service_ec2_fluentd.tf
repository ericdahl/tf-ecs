# Findings:
# - NLB doesn't support loopback to same instance.

# TODO:
# adjust health probe settings for faster NLB resolution on startup of forwarder?

data "template_file" "fluentd" {
  count    = var.enable_ec2_fluentd ? 1 : 0
  template = file("templates/tasks/fluentd-aggregator.json")
}

resource "aws_ecs_task_definition" "fluentd_aggregator" {
  count = var.enable_ec2_fluentd ? 1 : 0

  container_definitions = data.template_file.fluentd[0].rendered
  family                = "fluentd"
}

resource "aws_ecs_service" "fluentd_aggregator" {
  count = var.enable_ec2_fluentd ? 1 : 0

  cluster         = "tf-cluster"
  name            = "fluentd-aggregator"
  task_definition = aws_ecs_task_definition.fluentd_aggregator[0].arn
  desired_count   = "2"

  # to avoid possible race condition error on creation
  depends_on = [aws_lb.fluentd_aggregator]

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.fluentd_aggregator[0].arn
    container_name   = "fluentd-aggregator"
    container_port   = 24224
  }
}

resource "aws_lb" "fluentd_aggregator" {
  count = var.enable_ec2_fluentd ? 1 : 0

  name               = "fluentd"
  load_balancer_type = "network"
  internal           = true

  subnets = [
    module.vpc.subnet_private1,
    module.vpc.subnet_private2,
    module.vpc.subnet_private3,
  ]
}

resource "aws_lb_listener" "fluentd_aggregator" {
  count = var.enable_ec2_fluentd ? 1 : 0

  load_balancer_arn = aws_lb.fluentd_aggregator[0].arn
  port              = 24224
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.fluentd_aggregator[0].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "fluentd_aggregator" {
  count = var.enable_ec2_fluentd ? 1 : 0

  port     = 24224
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id
}

///////////////////////////////////////////////////
///
/// Forwarder
///
///////////////////////////////////////////////////

data "template_file" "fluentd_forwarder" {
  count    = var.enable_ec2_fluentd ? 1 : 0
  template = file("templates/tasks/fluentd-forwarder.json")

  vars = {
    fluentd_aggregator_host = aws_lb.fluentd_aggregator[0].dns_name
  }
}

resource "aws_ecs_task_definition" "fluentd_forwarder" {
  count = var.enable_ec2_fluentd ? 1 : 0

  container_definitions = data.template_file.fluentd_forwarder[0].rendered
  family                = "fluentd-forwarder"

  volume {
    name      = "var_log"
    host_path = "/var/log"
  }

  volume {
    name      = "etc_environment"
    host_path = "/etc/environment"
  }
}

resource "aws_ecs_service" "fluentd_forwarder" {
  count = var.enable_ec2_fluentd ? 1 : 0

  cluster             = "tf-cluster"
  name                = "fluentd-forwarder"
  task_definition     = aws_ecs_task_definition.fluentd_forwarder[0].arn
  scheduling_strategy = "DAEMON"

  depends_on = [aws_lb.fluentd_aggregator]
}

