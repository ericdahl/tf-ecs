resource "aws_ecs_cluster" "default" {
  name = var.cluster_name

  tags = {
    ClusterName = var.cluster_name
  }
}

data "aws_ssm_parameter" "ecs_amazon_linux_2" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "template_file" "cloud_init" {
  template = file("${path.module}/templates/cloud-init.yml")

  vars = {
    cluster_name = var.cluster_name
  }
}
