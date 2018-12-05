provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = "${var.admin_cidr}"
}

module "ecs" {
  source = "ecs_cluster"

  cluster_name = "tf-cluster"
}

//module "ecs_drainer" {
//  source = "ecs_drainer"
//
//  cluster_name = "${module.ecs.cluster_name}"
//
//  asg_names = [
//    "${module.ecs_asg_spot.name}",
//  ]
//}

//module "ecs_asg" {
//  source = "ecs_asg"
//  name   = "ecs-asg"
//
//  security_groups = [
//    "${module.vpc.sg_allow_egress}",
//    "${module.vpc.sg_allow_vpc}",
//    "${module.vpc.sg_allow_22}",
//    "${module.vpc.sg_allow_80}",
//    "${aws_security_group.allow_2376.id}",
//  ]
//
//  key_name = "${var.key_name}"
//
//  subnets = [
//    "${module.vpc.subnet_private1}",
//    "${module.vpc.subnet_private2}",
//    "${module.vpc.subnet_private3}",
//  ]
//
//  desired_size          = "${var.ecs_asg_desired_size}"
//  ami_id                = "${module.ecs.ami_id}"
//  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
//  user_data             = "${module.ecs.user-data}"
//}

module "ecs_asg_launch_template" {
  source = "ecs_asg_launch_template"
  name   = "ecs-asg-launch-template"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
    "${aws_security_group.allow_2376.id}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_private1}",
    "${module.vpc.subnet_private2}",
    "${module.vpc.subnet_private3}",
  ]

  desired_size          = "${var.ecs_asg_desired_size}"
  ami_id                = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  user_data             = "${module.ecs.user-data}"
}

//module "ecs_asg_spot" {
//  source = "ecs_asg"
//  name   = "ecs-asg-spot"
//
//  security_groups = [
//    "${module.vpc.sg_allow_egress}",
//    "${module.vpc.sg_allow_vpc}",
//    "${module.vpc.sg_allow_22}",
//    "${module.vpc.sg_allow_80}",
//    "${aws_security_group.allow_2376.id}",
//  ]
//
//  key_name = "${var.key_name}"
//
//  subnets = [
//    "${module.vpc.subnet_private1}",
//    "${module.vpc.subnet_private2}",
//    "${module.vpc.subnet_private3}",
//  ]
//
//  desired_size          = "${var.ecs_asg_spot_desired_size}"
//  min_size = "${var.asg_min_size}"
//  max_size = "${var.asg_max_size}"
//  instance_type         = "t2.medium"
//  spot_price            = "0.0464"
//  ami_id                = "${module.ecs.ami_id}"
//  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
//
//  user_data = "${module.ecs.user-data}"
//}
//
//module "ecs_asg_spot_2" {
//  source = "ecs_asg"
//  name   = "ecs-asg-spot_2"
//
//  security_groups = [
//    "${module.vpc.sg_allow_egress}",
//    "${module.vpc.sg_allow_vpc}",
//    "${module.vpc.sg_allow_22}",
//    "${module.vpc.sg_allow_80}",
//    "${aws_security_group.allow_2376.id}",
//  ]
//
//  key_name = "${var.key_name}"
//
//  subnets = [
//    "${module.vpc.subnet_private1}",
//    "${module.vpc.subnet_private2}",
//    "${module.vpc.subnet_private3}",
//  ]
//
//  desired_size          = "${var.ecs_asg_spot_desired_size}"
//  min_size = "${var.asg_min_size}"
//  max_size = "${var.asg_max_size}"
//  instance_type         = "t2.small"
//  spot_price            = "0.0464"
//  ami_id                = "${module.ecs.ami_id}"
//  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
//
//  user_data = "${module.ecs.user-data}"
//}

//module "asg_autoscale_target_tracking" {
//  source = "ecs_autoscaling_target_tracking"
//
//  asg_name = "${module.ecs_asg_spot.name}"
//  cluster_name = "${module.ecs.cluster_name}"
//}

//module "asg_autoscale_target_tracking_2" {
//  source = "ecs_autoscaling_target_tracking"
//
//  asg_name = "${module.ecs_asg_spot_2.name}"
//  cluster_name = "${module.ecs.cluster_name}"
//}
//
//module "ecs_spot_fleet" {
//  source = "ecs_spot_fleet"
//
//  cluster_name = "${module.ecs.cluster_name}"
//
//  security_groups = [
//    "${module.vpc.sg_allow_egress}",
//    "${module.vpc.sg_allow_vpc}",
//    "${module.vpc.sg_allow_22}",
//    "${module.vpc.sg_allow_80}",
//    "${aws_security_group.allow_2376.id}",
//  ]
//
//  key_name = "${var.key_name}"
//
//  subnets = [
//    "${module.vpc.subnet_private1}",
//    "${module.vpc.subnet_private2}",
//    "${module.vpc.subnet_private3}",
//  ]
//
//  ami_id = "${module.ecs.ami_id}"
//
//  target_capacity = "${var.ecs_spot_fleet_desired_size}"
//
//  user_data             = "${module.ecs.user-data}"
//  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
//  valid_until           = "2018-12-01T00:00:00Z"
//  iam_fleet_role_arn    = "${module.ecs.iam_role_fleet_arn}"
//}

//module "ecs_autoscaling" {
//  source       = "ecs_autoscaling"
//  cluster_name = "${module.ecs.cluster_name}"
//
//  scale_up_actions = [
//    "${module.ecs_asg.asg_scale_up_arn}",
//    "${module.ecs_asg_spot.asg_scale_up_arn}",
//    "${module.ecs_spot_fleet.fleet_scale_up_arn}",
//  ]
//
//  scale_down_actions = [
//    "${module.ecs_asg.asg_scale_down_arn}",
//    "${module.ecs_asg_spot.asg_scale_down_arn}",
//    "${module.ecs_spot_fleet.fleet_scale_down_arn}",
//  ]
//}

resource "aws_security_group" "allow_2376" {
  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_security_group_rule" "allow_2376" {
  security_group_id = "${aws_security_group.allow_2376.id}"
  from_port         = 2376
  protocol          = "tcp"
  to_port           = 2376
  type              = "ingress"
  cidr_blocks       = ["${var.admin_cidr}"]
}

data "aws_ami" "freebsd_11" {
  most_recent = true

  filter {
    name = "owner-id"

    values = [
      "118940168514",
    ]
  }

  filter {
    name = "name"

    values = [
      "FreeBSD 11.1-STABLE-amd64*",
    ]
  }
}

resource "aws_instance" "jumphost" {
  ami                    = "${data.aws_ami.freebsd_11.image_id}"
  instance_type          = "t2.small"
  subnet_id              = "${module.vpc.subnet_public1}"
  vpc_security_group_ids = ["${module.vpc.sg_allow_22}", "${module.vpc.sg_allow_egress}"]
  key_name               = "${var.key_name}"

  user_data = <<EOF
#!/usr/bin/env sh

export ASSUME_ALWAYS_YES=YES

pkg update -y
pkg install -y bash
chsh -s /usr/local/bin/bash ec2-user
EOF

  tags {
    Name = "jumphost"
  }
}
