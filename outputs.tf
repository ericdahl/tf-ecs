output "ami_id" {
  value = "${data.aws_ami.ecs.id}"
}

output "iam_role_ecs_service_name" {
  value = "${aws_iam_role.ecs_service.name}"
}