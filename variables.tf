variable "cluster_name" {}

variable "security_groups" {
  type = "list"
}

variable "key_name" {}

variable "subnets" {
  type = "list"
}

variable "min_size" {
  default = 3
}

variable "max_size" {
  default = 3
}
