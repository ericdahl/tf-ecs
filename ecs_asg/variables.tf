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
  type = list(string)
}

variable "name" {}

variable "ami_id" {}

variable "instance_type" {
  default = "t2.small"
}

variable "instance_profile_name" {}

variable "security_groups" {
  type = list(string)
}

variable "user_data" {}

variable "key_name" {}

variable "spot_price" {
  default = ""
}

variable "overrides" {
  type = list(map(string))
}

variable "on_demand_percentage_above_base_capacity" {
  default = 0
}
