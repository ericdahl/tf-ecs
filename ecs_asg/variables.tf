variable "min_size" {
  default = 1
}
variable "max_size" {
  default = 5
}
variable "desired_size" {
  default = 3
}

variable "subnets" {
  type = "list"
}

variable "name" {}

variable "ami_id" {}

variable "instance_type" {
  default = "t2.small"
}

variable "instance_profile_name" {}

variable "security_groups" {
  type = "list"
}

variable "user_data" {}

variable "key_name" {
}
