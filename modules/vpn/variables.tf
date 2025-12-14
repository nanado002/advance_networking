variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "onprem_cidr" {
  type = string
}

variable "tgw_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "vpn_preshared_key_1" {
  type      = string
  sensitive = true
}

variable "vpn_preshared_key_2" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
}