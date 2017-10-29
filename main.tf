provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "default" {
  name = "${var.cluster_name}"
}

data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized*"]
  }
}

data "template_file" "ecs_user_data" {
  template = "${file("${path.module}/templates/ecs-user-data.sh")}"

  vars {
    cluster_name = "${var.cluster_name}"
  }
}


resource "aws_autoscaling_group" "default" {
  launch_configuration = "${aws_launch_configuration.default.id}"
  max_size             = "${var.min_size}"
  min_size             = "${var.max_size}"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_zone_identifier  = ["${var.subnets}"]
}

resource "aws_launch_configuration" "default" {
  image_id      = "${data.aws_ami.ecs.image_id}"
  instance_type = "${var.instance_type}"

  iam_instance_profile = "${aws_iam_instance_profile.default.name}"

  key_name = "${var.key_name}"

  security_groups = ["${var.security_groups}"]

  user_data = "${data.template_file.ecs_user_data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}