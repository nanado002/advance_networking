resource "aws_ec2_transit_gateway" "this" {
  description                     = var.name
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  tags                            = merge(var.tags, { Name = var.name })
}