provider "aws" {
  region = "us-east-1"
}

variable "key_name" {}

variable "desired_size" {
  default = 3
}

variable "admin_cidr" {
  default = "0.0.0.0/0"
}

variable "enable_fargate" {
  default = "true"
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

  asg_names =  [
    "${module.ecs_asg.name}",
    "${module.ecs_asg_spot.name}"
  ]
}




module "ecs_asg" {
  source = "ecs_asg"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
    "${aws_security_group.allow_2376.id}"
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  min_size = 0
  desired_size = "${var.desired_size}"
  max_size = 5
  ami_id = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  name = "ecs-asg"
  user_data = "${module.ecs.user-data}"
}


module "ecs_asg_spot" {
  source = "ecs_asg"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_vpc}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
    "${aws_security_group.allow_2376.id}"
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]

  min_size = 1
  desired_size = "3"
  max_size = 5
  instance_type = "t2.medium"
  spot_price = "0.0135"
  ami_id = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  name = "ecs-asg-spot"
  user_data = "${module.ecs.user-data}"
}


resource "aws_security_group" "allow_2376" {
  vpc_id = "${module.vpc.vpc_id}"
}

resource "aws_security_group_rule" "allow_2376" {
  security_group_id = "${aws_security_group.allow_2376.id}"
  from_port = 2376
  protocol = "tcp"
  to_port = 2376
  type = "ingress"
  cidr_blocks = ["${var.admin_cidr}"]
}
