variable "name" {
  default = "ecs_spot_fleet"
}

variable "subnets" {
  type = "list"
}

variable "valid_until" {}

variable "ami_id" {}

variable "iam_fleet_role_arn" {}

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

variable "min_size" {
  default = 0
}

variable "max_size" {
  default = 5
}

variable "allocation_strategy" {
  default = "diversified"
}
