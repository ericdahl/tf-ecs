provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source = "github.com/ericdahl/tf-module-vpc"
}

module "ecs" {
  source = "ecs_cluster"

  cluster_name = "tf-cluster"
}

module "ecs_drainer" {
  source = "ecs_drainer"

  cluster_name = "${module.ecs.cluster_name}"

  asg_names = [
    "${module.ecs_asg.name}",
    "${module.ecs_asg_spot.name}",
  ]
}

module "ecs_asg" {
  source = "ecs_asg"
  name   = "ecs-asg"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
    "${aws_security_group.allow_2376.id}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  desired_size          = "${var.ecs_asg_desired_size}"
  ami_id                = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  user_data             = "${module.ecs.user-data}"
}

module "ecs_asg_spot" {
  source = "ecs_asg"
  name   = "ecs-asg-spot"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
    "${aws_security_group.allow_2376.id}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  desired_size          = "${var.ecs_asg_spot_desired_size}"
  instance_type         = "t2.medium"
  spot_price            = "0.0464"
  ami_id                = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"

  user_data = "${module.ecs.user-data}"
}

module "ecs_spot_fleet" {
  source = "ecs_spot_fleet"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
    "${aws_security_group.allow_2376.id}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  ami_id = "${module.ecs.ami_id}"

  target_capacity = "${var.ecs_spot_fleet_desired_size}"

  user_data             = "${module.ecs.user-data}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  instance_type         = "t2.large"
  spot_price            = "0.0928"
  valid_until           = "2018-07-01T00:00:00Z"
}

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
