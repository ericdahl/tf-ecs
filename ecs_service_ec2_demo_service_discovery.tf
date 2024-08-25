resource "aws_ecs_task_definition" "demo_service_discovery" {
  count  = var.enable_ec2_demo_service_discovery ? 1 : 0
  family = "demo_service_discovery"

  container_definitions = templatefile("templates/tasks/demo_service_discovery.json", {})
}

resource "aws_ecs_service" "demo_service_discovery" {
  count = var.enable_ec2_demo_service_discovery ? 1 : 0

  cluster         = "tf-cluster"
  name            = "tf-cluster-demo-service-discovery"
  task_definition = aws_ecs_task_definition.demo_service_discovery[0].arn
  desired_count   = "6"

  service_registries {
    registry_arn = aws_service_discovery_service.demo_service_discovery[0].arn

    container_port = 8080
    container_name = "httpbin"
  }
}

resource "aws_service_discovery_private_dns_namespace" "demo_service_discovery" {
  count = var.enable_ec2_demo_service_discovery ? 1 : 0

  name = "demo.int"
  vpc  = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "demo_service_discovery" {
  count = var.enable_ec2_demo_service_discovery ? 1 : 0

  name = "demo-service-discovery"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.demo_service_discovery[0].id

    dns_records {
      ttl  = 10
      type = "SRV"
    }
  }
}

