variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "adv-net-lowcost"
}

variable "shared_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "app_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "onprem_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "vpn_preshared_key_1" {
  type      = string
  default   = "superSecretKey123"
  sensitive = true
}

variable "vpn_preshared_key_2" {
  type      = string
  default   = "anotherSecretKey456"
  sensitive = true
}

variable "flow_log_retention_days" {
  type    = number
  default = 7
}
