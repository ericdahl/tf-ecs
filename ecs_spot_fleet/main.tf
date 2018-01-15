resource "aws_spot_fleet_request" "default" {
  iam_fleet_role  = "${aws_iam_role.fleet.arn}"
  spot_price      = "${var.spot_price}"
  target_capacity = "${var.target_capacity}"
  valid_until     = "${var.valid_until}"
  allocation_strategy = "${var.allocation_strategy}" # TODO: one fleet request per AZ ..?

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
}

resource "aws_iam_role" "fleet" {
  name = "iam_fleet_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "spotfleet.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "fleet_terminate_name" {
  role       = "${aws_iam_role.fleet.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}
