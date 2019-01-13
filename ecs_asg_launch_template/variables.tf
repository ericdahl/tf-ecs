variable "min_size" {
  default = 0
}

variable "max_size" {
  default = 10
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

variable "key_name" {}

variable "spot_price" {
  default = ""
}

variable "overrides" {
  type = "list"
}

variable "on_demand_percentage_above_base_capacity" {
  default = 0
}
