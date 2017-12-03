data "template_file" "httpbin" {
  template = "${file("templates/tasks/httpbin.json")}"
}

resource "aws_ecs_task_definition" "httpbin" {
  container_definitions = "${data.template_file.httpbin.rendered}"
  family                = "httpbin"
}

resource "aws_ecs_service" "httpbin" {
  cluster         = "tf-cluster"
  name            = "tf-cluster-httpbin"
  task_definition = "${aws_ecs_task_definition.httpbin.arn}"
  desired_count   = "12"

  iam_role = "${module.ecs.iam_role_ecs_service_name}"

  # to avoid possible race condition error on creation
  depends_on = ["aws_alb.default"]

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.default.arn}"
    container_name   = "httpbin"
    container_port   = 8080
  }
}



resource "aws_alb" "default" {
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

resource "aws_alb_listener" "default" {
  "default_action" {
    target_group_arn = "${aws_alb_target_group.default.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.default.arn}"
  port              = 80
}

resource "aws_alb_target_group" "default" {
  vpc_id               = "${module.vpc.vpc_id}"
  port                 = 8080
  protocol             = "HTTP"
  deregistration_delay = 1

  health_check {
    # The service task needs to start up and respond to health probes in
    #
    # unhealthy_threshold * (interval + [0, timeout])
    #
    # If the probes can't connect to the target then it's immediately recorded
    # as a failed health check. This would happen if the target is initializing and
    # hasn't started listening on the socket.
    #
    # e.g.,
    #   timeout = 2, unhealthy_threshold = 3, interval = 5
    # The target has between 15 and 21 seconds to respond to health checks depending
    # on whether it's accepting connections.
    #
    # This does not seem to be exact. When using a task that takes a constant 30 seconds
    # to accept connections, even some tasks managed to get through the health check after
    # 20+ repeated failed attempts with 2/3/5.

    healthy_threshold = 2
    unhealthy_threshold = 8
    interval = 5
    timeout = 2
  }
}
