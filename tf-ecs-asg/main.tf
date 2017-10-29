provider "aws" {
  region = "us-east-1"
}

resource "aws_autoscaling_group" "default" {
  launch_configuration = "${aws_launch_configuration.default.id}"
  max_size             = 1
  min_size             = 1
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  vpc_zone_identifier  = ["${var.subnets}"]
}

resource "aws_launch_configuration" "default" {
  image_id      = "${var.image_id}"
  instance_type = "${var.instance_type}"

  iam_instance_profile = "${var.iam_instance_profile}"

  key_name = "${var.key_name}"

  security_groups = ["${var.security_groups}"]

  user_data = "${var.user_data}"

  lifecycle {
    create_before_destroy = true
  }
}
