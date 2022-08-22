#resource "aws_ecs_task_definition" "httpbin_large" {
#  family                = "httpbin-large"
#
#  container_definitions = templatefile("templates/tasks/httpbin-large.json", {
#    delay_start_connect: 0
#  })
#}
#
#resource "aws_ecs_service" "httpbin_large" {
#
#
#  cluster         = aws_ecs_cluster.default.name
#  name            = "tf-cluster-httpbin-large"
#  task_definition = aws_ecs_task_definition.httpbin_large.arn
#  desired_count   = 1
#
#  deployment_circuit_breaker {
#    enable   = true
#    rollback = true
#  }
#
#  enable_ecs_managed_tags = "true"
#  propagate_tags          = "SERVICE"
#  tags = {
#    ServiceName = "tf-cluster-httpbin-large"
#    ClusterName = "tf-cluster"
#  }
#
#
#  ordered_placement_strategy {
#    type  = "spread"
#    field = "attribute:ecs.availability-zone"
#  }
#
#  ordered_placement_strategy {
#    type  = "spread"
#    field = "instanceId"
#  }
#
#  lifecycle {
#    ignore_changes = [
#      desired_count,
#      capacity_provider_strategy
#    ]
#  }
#}
#
#
