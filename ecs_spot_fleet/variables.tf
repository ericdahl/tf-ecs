variable "name" {
  default = "ecs_spot_fleet"
}

variable "subnets" {
  type = "list"
}

variable "valid_until" {}

variable "ami_id" {}

variable "instance_type" {
  default = "t2.large"
}

variable "instance_profile_name" {}

variable "security_groups" {
  type = "list"
}

variable "user_data" {}

variable "key_name" {}

variable "spot_price" {}

variable "target_capacity" {
  default = 3
}
