provider "aws" {
  region = "us-east-1"
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

module "ecs_asg" {
  source = "./ecs_asg"
  name   = "ecs-asg-launch-template"

  security_groups = [
    module.vpc.sg_allow_egress,
    module.vpc.sg_allow_vpc,
    module.vpc.sg_allow_22,
    module.vpc.sg_allow_80,
    aws_security_group.allow_2376.id,
  ]

  key_name = var.key_name

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
      instance_type = "m1.small"
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

  ami_id                = module.ecs.ami_id
//  ami_id = "resolve:ssm/tf-ecs/ami-id"
  instance_profile_name = module.ecs.iam_instance_profile_name
  user_data             = module.ecs.user-data
}


data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

resource "aws_security_group" "allow_2376" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group_rule" "allow_2376" {
  security_group_id = aws_security_group.allow_2376.id
  from_port         = 2376
  protocol          = "tcp"
  to_port           = 2376
  type              = "ingress"
  cidr_blocks       = [var.admin_cidr]
}

data "aws_ami" "freebsd" {
  owners = [782442783595]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["FreeBSD 12.1-RELEASE-amd64"]
  }

  most_recent = true
}

resource "aws_instance" "jumphost" {
  ami                    = data.aws_ami.freebsd.image_id
  instance_type          = "t2.small"
  subnet_id              = module.vpc.subnet_public1
  vpc_security_group_ids = [module.vpc.sg_allow_22, module.vpc.sg_allow_egress]
  key_name               = var.key_name

  user_data = <<EOF
#!/usr/bin/env sh

export ASSUME_ALWAYS_YES=YES

pkg update -y
pkg install -y bash
chsh -s /usr/local/bin/bash ec2-user
EOF


  tags = {
    Name = "jumphost"
  }
}

