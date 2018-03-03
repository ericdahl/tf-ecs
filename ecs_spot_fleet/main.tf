resource "aws_spot_fleet_request" "default" {
  iam_fleet_role                      = "${var.iam_fleet_role_arn}"
  spot_price                          = "${var.spot_price}"
  target_capacity                     = "${var.target_capacity}"
  valid_until                         = "${var.valid_until}"
  allocation_strategy                 = "${var.allocation_strategy}" # TODO: one fleet request per AZ ..?
  terminate_instances_with_expiration = true

  launch_specification {
    ami                    = "${var.ami_id}"
    instance_type          = "${var.instance_type}"
    subnet_id              = "${element(var.subnets, 0)}"
    key_name               = "${var.key_name}"
    vpc_security_group_ids = ["${var.security_groups}"]
    iam_instance_profile   = "${var.instance_profile_name}"
    user_data              = "${var.user_data}"

    tags {
      Name = "${var.name}"
    }
  }

  launch_specification {
    ami                    = "${var.ami_id}"
    instance_type          = "${var.instance_type}"
    subnet_id              = "${element(var.subnets, 1)}"
    key_name               = "${var.key_name}"
    vpc_security_group_ids = ["${var.security_groups}"]
    iam_instance_profile   = "${var.instance_profile_name}"
    user_data              = "${var.user_data}"

    tags {
      Name = "${var.name}"
    }
  }

  launch_specification {
    ami                    = "${var.ami_id}"
    instance_type          = "${var.instance_type}"
    subnet_id              = "${element(var.subnets, 2)}"
    key_name               = "${var.key_name}"
    vpc_security_group_ids = ["${var.security_groups}"]
    iam_instance_profile   = "${var.instance_profile_name}"
    user_data              = "${var.user_data}"

    tags {
      Name = "${var.name}"
    }
  }

  lifecycle {
    ignore_changes = ["target_capacity"]
  }
}

data "aws_iam_role" "iam_role_autoscale_fleet" {
  name = "AWSServiceRoleForApplicationAutoScaling_EC2SpotFleetRequest"
}

resource "aws_appautoscaling_target" "default" {
  max_capacity       = "${var.max_size}"
  min_capacity       = "${var.min_size}"
  resource_id        = "spot-fleet-request/${aws_spot_fleet_request.default.id}"
  role_arn           = "${data.aws_iam_role.iam_role_autoscale_fleet.arn}"
  scalable_dimension = "ec2:spot-fleet-request:TargetCapacity"
  service_namespace  = "ec2"

  depends_on = ["aws_spot_fleet_request.default"]
}

resource "aws_appautoscaling_policy" "scale_down" {
  name = "${var.name}_scale_down"

  scalable_dimension = "ec2:spot-fleet-request:TargetCapacity"
  service_namespace  = "ec2"
  resource_id        = "spot-fleet-request/${aws_spot_fleet_request.default.id}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = ["aws_appautoscaling_target.default"]
}

resource "aws_appautoscaling_policy" "scale_up" {
  name = "${var.name}_scale_up"

  scalable_dimension = "ec2:spot-fleet-request:TargetCapacity"
  service_namespace  = "ec2"
  resource_id        = "spot-fleet-request/${aws_spot_fleet_request.default.id}"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = ["aws_appautoscaling_target.default"]
}
