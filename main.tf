provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "default" {
  name = "${var.cluster_name}"
}

data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized*"]
  }
}

data "template_file" "ecs_user_data" {
  template = "${file("${path.module}/templates/ecs-user-data.sh")}"

  vars {
    cluster_name = "${var.cluster_name}"
  }
}

module "ecs_asg" {
  source               = "tf-ecs-asg"
  image_id             = "${data.aws_ami.ecs.id}"
  instance_type        = "t2.small"
  iam_instance_profile = "${aws_iam_instance_profile.default.id}"
  security_groups      = "${var.security_groups}"
  subnets              = "${var.subnets}"
  key_name             = "${var.key_name}"
  cluster_name         = "${var.cluster_name}"
  user_data            = "${data.template_file.ecs_user_data.rendered}"
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
}
