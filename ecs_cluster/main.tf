resource "aws_ecs_cluster" "default" {
  name = var.cluster_name

  tags = {
    ClusterName = var.cluster_name
  }
}



data "template_file" "cloud_init" {
  template = file("${path.module}/templates/cloud-init.yml")

  vars = {
    cluster_name = var.cluster_name
  }
}
