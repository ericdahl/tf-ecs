variable "cluster_name" {
  default = "tf-cluster"
}

variable "security_groups" {
  type = "list"
}

variable "key_name" {}

variable "subnets" {
  type = "list"
}
