output "ami_id" {
  value = "${data.aws_ami.ecs.id}"
}
