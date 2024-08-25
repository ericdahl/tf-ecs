provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Name        = "tf-ecs"
      Provisioner = "Terraform"
      Repository  = "https://github.com/ericdahl/tf-ecs"
    }
  }
}

terraform {
  required_version = "> 0.12.0"
}

module "vpc" {
  source = "github.com/ericdahl/tf-vpc"
}

resource "aws_ecs_capacity_provider" "default" {
  name = var.name
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.default.arn

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100


    }
    managed_termination_protection = "DISABLED"
    managed_draining               = "ENABLED"


  }
}

resource "aws_ecs_cluster" "default" {
  name = var.name
}

resource "aws_ecs_cluster_capacity_providers" "default" {
  cluster_name = aws_ecs_cluster.default.name

  capacity_providers = [aws_ecs_capacity_provider.default.name]

  default_capacity_provider_strategy {
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.default.name
  }
}


data "template_file" "cloud_init" {
  template = file("${path.module}/templates/cloud-init.yml")

  vars = {
    cluster_name = var.name
  }
}




resource "aws_security_group" "ecs_instance" {
  vpc_id = module.vpc.vpc_id
  name   = "ecs"

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


resource "aws_security_group_rule" "ecs_instance_ingress_vpc" {
  security_group_id = aws_security_group.ecs_instance.id
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["10.0.0.0/8"] # TODO: remove rule and replace with specific
}





data "aws_ssm_parameter" "ecs_amazon_linux_2" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

data "aws_ssm_parameter" "ecs_bottlerocket" {
  name = "/aws/service/bottlerocket/aws-ecs-1/x86_64/latest/image_id"
}

data "aws_iam_role" "autoscaling" {
  name = "AWSServiceRoleForApplicationAutoScaling_ECSService"
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2" {
  name        = "${var.name}-instance-role"
  description = "Role applied to ECS container instances - EC2 hosts - allowing them to register themselves, pull images from ECR, etc."

  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

resource "aws_iam_policy_attachment" "ec2_ecs" {
  name       = "${aws_ecs_cluster.default.name}-ec2"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_policy_attachment" "ec2_ssm" {
  name       = "${aws_ecs_cluster.default.name}-ec2"
  roles      = [aws_iam_role.ec2.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "ecs_ec2" {
  name = "${aws_iam_role.ec2.name}-instance-profile"
  role = aws_iam_role.ec2.name
}