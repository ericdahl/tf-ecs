provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "default" {
  name = "${var.cluster_name}"

  tags = {
    ClusterName = "${var.cluster_name}"
  }
}

data "aws_ami" "ecs" {
  most_recent = true

  owners = [ "591542846629" ]

  filter {
    name   = "name"
    values = ["*amazon-ecs-optimized*"]
  }
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/templates/cloud-init.yml")}"

  vars {
    cluster_name = "${var.cluster_name}"
  }
}
