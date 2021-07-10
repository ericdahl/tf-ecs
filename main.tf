provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name = "tf-ecs"
    }
  }
}

terraform {
  required_version = "> 0.12.0"
}

module "vpc" {
  source        = "github.com/ericdahl/tf-vpc"
  admin_ip_cidr = var.admin_cidr
}

module "ecs" {
  source = "./ecs_cluster"

  cluster_name = "tf-cluster"
}

locals {
  user_data_bottlerocket = <<EOF
[settings.ecs]
cluster = "${module.ecs.cluster_name}"

[settings.host-containers.admin]
enabled = true
EOF
}

resource "aws_security_group" "ecs_instance" {
  vpc_id = module.vpc.vpc_id
  name = "ecs"

  tags = {
    Name = "ecs-instance"
  }
}


resource "aws_security_group_rule" "ecs_instance_egress" {
  security_group_id = aws_security_group.ecs_instance.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_instance_ingress_ssh" {
  security_group_id = aws_security_group.ecs_instance.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = aws_security_group.jumphost.id
}

resource "aws_security_group_rule" "ecs_instance_ingress_vpc" {
  security_group_id = aws_security_group.ecs_instance.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.0.0.0/8"] # TODO: remove rule and replace with specific
}

module "ecs_asg" {
  source = "./ecs_asg"
  name   = "ecs-asg-launch-template"

  security_groups = [
    aws_security_group.ecs_instance.id
  ]

  key_name = aws_key_pair.key.key_name

  subnets = [
    module.vpc.subnet_private1,
    module.vpc.subnet_private2,
    module.vpc.subnet_private3,
  ]

  instance_type = "t2.small"

  overrides = [
    {
      instance_type = "t2.medium"
    },
    {
      instance_type = "t2.large"
    },
    {
      instance_type = "m3.medium"
    },
    {
      instance_type = "c4.large"
    },
  ]

  min_size     = var.asg_min_size
  desired_size = var.asg_desired_size
  max_size     = var.asg_max_size

  ami_id                = data.aws_ssm_parameter.ecs_bottlerocket.value
  instance_profile_name = module.ecs.iam_instance_profile_name
  user_data             = local.user_data_bottlerocket
}

data "aws_ssm_parameter" "ecs_amazon_linux_2" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_ssm_parameter" "ecs_bottlerocket" {
  name = "/aws/service/bottlerocket/aws-ecs-1/x86_64/latest/image_id"
}

data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

resource "aws_key_pair" "key" {
  public_key = var.ssh_public_key
}

