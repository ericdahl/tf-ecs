# TODO:
# dynamic fluentd aggregaor URL
# annotate forwarder with host name/instance id

data "template_file" "fluentd" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"
  template = "${file("templates/tasks/fluentd-aggregator.json")}"
}


resource "aws_ecs_task_definition" "fluentd" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.fluentd.rendered}"
  family                = "fluentd"
}

resource "aws_ecs_service" "fluentd" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  cluster         = "tf-cluster"
  name            = "fluentd-aggregator"
  task_definition = "${aws_ecs_task_definition.fluentd.arn}"
  desired_count   = "1"

  iam_role = "${module.ecs.iam_role_ecs_service_name}"

  # to avoid possible race condition error on creation
  depends_on = ["aws_lb.fluentd"]


  load_balancer {
    target_group_arn = "${aws_lb_target_group.fluentd.arn}"
    container_name   = "fluentd-aggregator"
    container_port   = 24224
  }
}


resource "aws_lb" "fluentd" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  name = "fluentd"
  load_balancer_type = "network"
  internal = true

  subnets = [
    "${module.vpc.subnet_private1}",
    "${module.vpc.subnet_private2}",
    "${module.vpc.subnet_private3}",
  ]
}

resource "aws_lb_listener" "fluentd" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  load_balancer_arn = "${aws_lb.fluentd.arn}"
  port = 24224
  protocol = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.fluentd.arn}"
    type = "forward"
  }
}

resource "aws_lb_target_group" "fluentd" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  port = 24224
  protocol = "TCP"
  vpc_id = "${module.vpc.vpc_id}"
}


///////////////////////////////////////////////////
///
/// Forwarder
///
///////////////////////////////////////////////////

data "template_file" "fluentd_forwarder" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"
  template = "${file("templates/tasks/fluentd-forwarder.json")}"
}

resource "aws_ecs_task_definition" "fluentd_forwarder" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.fluentd_forwarder.rendered}"
  family                = "fluentd-forwarder"

  volume {
    name      = "var_log"
    host_path = "/var/log"
  }
}

resource "aws_ecs_service" "fluentd_forwarder" {
  count = "${var.enable_ec2_fluentd == "true" ? 1 : 0}"

  cluster             = "tf-cluster"
  name                = "fluentd-forwarder"
  task_definition     = "${aws_ecs_task_definition.fluentd_forwarder.arn}"
  scheduling_strategy = "DAEMON"
}
