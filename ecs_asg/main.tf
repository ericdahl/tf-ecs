resource "aws_autoscaling_group" "default" {
  name = var.name

  launch_configuration = aws_launch_configuration.default.id
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_size

  availability_zones = [
    "us-east-1a",
    "us-east-1b",
    "us-east-1c",
  ]

  vpc_zone_identifier = [
    var.subnets,
  ]

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_launch_configuration" "default" {
  name_prefix   = var.name
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile = var.instance_profile_name

  key_name = var.key_name

  security_groups = [
    var.security_groups,
  ]

  user_data  = var.user_data
  spot_price = var.spot_price

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = format("%s-%s", var.name, "scale_up")
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.default.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = format("%s-%s", var.name, "scale_down")
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.default.name
}
