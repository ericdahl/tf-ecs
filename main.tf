provider "aws" {
  region = "us-east-1"
}

variable "key_name" {}

variable "desired_size" {
  default = 5
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

  asg_names =  ["${module.ecs_asg.name}"]
}

module "ecs_asg" {
  source = "ecs_asg"

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

  min_size = 1
  desired_size = "${var.desired_size}"
  max_size = 5
  ami_id = "${module.ecs.ami_id}"
  instance_profile_name = "${module.ecs.iam_instance_profile_name}"
  name = "ecs-asg"
  user_data = "${module.ecs.user-data}"
}
