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

  ami_id                = module.ecs.ami_id
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


resource "aws_key_pair" "key" {
  public_key = var.ssh_public_key
}

data "aws_ssm_parameter" "amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "jumphost" {
  ami                    = data.aws_ssm_parameter.amazon_linux_2_ami.value
  instance_type          = "t2.small"
  subnet_id              = module.vpc.subnet_public1
  vpc_security_group_ids = [module.vpc.sg_allow_22, module.vpc.sg_allow_egress]
  key_name               = aws_key_pair.key.key_name

  tags = {
    Name = "jumphost"
  }
}

