resource "aws_autoscaling_group" "default" {
  launch_configuration = "${aws_launch_configuration.default.id}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  desired_capacity     = "${var.desired_size}"

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  vpc_zone_identifier = [
    "${var.subnets}",
  ]

  name = "${var.name}"

  tag {
    key                 = "Name"
    value               = "${var.name}"
    propagate_at_launch = true
  }
}

resource "aws_launch_configuration" "default" {
  image_id      = "${var.ami_id}"
  instance_type = "${var.instance_type}"

  iam_instance_profile = "${var.instance_profile_name}"

  key_name = "${var.key_name}"

  security_groups = [
    "${var.security_groups}",
  ]

  user_data  = "${var.user_data}"
  spot_price = "${var.spot_price}"

  lifecycle {
    create_before_destroy = true
  }
}
