variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "tgw_id" {
  type = string
}

variable "vpn_connection_id" {
  type = string
}

variable "vpc_ids" {
  type = map(string)
}

variable "flow_log_retention_days" {
  type    = number
  default = 7
}

variable "tags" {
  type = map(string)
}
