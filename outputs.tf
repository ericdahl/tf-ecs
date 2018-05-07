output "alb_dns_name_httpbin_ec2" {
  value = ["${compact(concat(aws_alb.ecs_service_httpbin.*.id))}"]
}


output "aws_instance.jumphost.public_ip" {
  value = "${aws_instance.jumphost.public_ip}"
}


output "ecs_service_httpbin_ec2_alb" {
    value = "${join("", aws_alb.ecs_service_httpbin.*.dns_name)}"
}