variable "image_id" {}

variable "instance_type" {}

variable "iam_instance_profile" {}

variable "key_name" {}

variable "security_groups" {
  type = "list"
}

variable "subnets" {
  type = "list"
}

variable "cluster_name" {}

variable "user_data" {}
