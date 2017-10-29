provider "aws" {
  region = "us-east-1"
}

variable "key_name" {}

module "ecs" {
  source = "../"

  cluster_name = "tf-cluster"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]
}

module "vpc" {
  source = "github.com/ericdahl/tf-module-vpc"
}

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
  deregistration_delay = 10

  health_check {
    healthy_threshold = 2
    interval = 5
    timeout = 2
  }
}
