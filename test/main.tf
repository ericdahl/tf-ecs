provider "aws" {
  region = "us-east-1"
}

variable "key_name" {}

module "ecs" {
  source = "../"

  security_groups = [
    "${module.vpc.sg_allow_egress}",
    "${module.vpc.sg_allow_22}",
    "${module.vpc.sg_allow_80}",
  ]

  key_name = "${var.key_name}"

  subnets = [
    "${module.vpc.subnet_public1}",
    "${module.vpc.subnet_public2}",
    "${module.vpc.subnet_public3}",
  ]
}

module "vpc" {
  source = "github.com/ericdahl/tf-module-vpc"
}
