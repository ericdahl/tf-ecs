data "template_file" "httpbin_fargate" {
  template = "${file("templates/tasks/httpbin-fargate.json")}"
}

resource "aws_ecs_task_definition" "httpbin_fargate" {
  count = "${var.enable_fargate_httpbin == "true" ? 1 : 0}"

  container_definitions = "${data.template_file.httpbin_fargate.rendered}"
  family                = "httpbin-fargate"

  requires_compatibilities = [
    "FARGATE",
  ]

  network_mode = "awsvpc"
  cpu          = 256
  memory       = 512
}

resource "aws_ecs_service" "httpbin_fargate" {
  count = "${var.enable_fargate_httpbin == "true" ? 1 : 0}"

  name            = "httpbin-fargate"
  cluster         = "${module.ecs.cluster_name}"
  task_definition = "${aws_ecs_task_definition.httpbin_fargate.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      "${module.vpc.sg_allow_8080}",
      "${module.vpc.sg_allow_egress}",
      "${module.vpc.sg_allow_vpc}",
    ]

    subnets = [
      "${module.vpc.subnet_private1}",
    ]
  }

  depends_on = ["aws_alb.httpbin_fargate"]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.httpbin_fargate.arn}"
    container_name   = "httpbin"
    container_port   = 8080
  }
}

resource "aws_alb" "httpbin_fargate" {
  count = "${var.enable_fargate_httpbin == "true" ? 1 : 0}"

  name = "httpbin-fargate"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_80}",
  ]
}

resource "aws_alb_listener" "httpbin_fargate" {
  count = "${var.enable_fargate_httpbin == "true" ? 1 : 0}"

  default_action {
    target_group_arn = "${aws_alb_target_group.httpbin_fargate.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.httpbin_fargate.arn}"
  port              = 80
}

resource "aws_alb_target_group" "httpbin_fargate" {
  count = "${var.enable_fargate_httpbin == "true" ? 1 : 0}"

  name                 = "httpbin-fargate"
  vpc_id               = "${module.vpc.vpc_id}"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 5
  target_type          = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    interval            = 5
    timeout             = 2
  }
}
