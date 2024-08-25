#output "ecs_service_httpbin_ec2_alb" {
#  value = join("", aws_alb.ecs_service_httpbin.*.dns_name)
#}

