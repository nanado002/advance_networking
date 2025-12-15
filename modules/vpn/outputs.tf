output "vpn_connection_id" {
  description = "ID of the VPN connection"
  value       = aws_vpn_connection.this.id
}

output "strongswan_instance_id" {
  description = "ID of the StrongSwan instance"
  value       = aws_instance.strongswan.id
}

output "strongswan_public_ip" {
  description = "Public IP of the StrongSwan instance"
  value       = aws_instance.strongswan.public_ip
}

output "vpn_attachment_id" {
  description = "Transit Gateway attachment ID for the VPN connection"
  value       = aws_vpn_connection.this.transit_gateway_attachment_id
}

output "customer_gateway_id" {
  description = "ID of the customer gateway"
  value       = aws_customer_gateway.this.id
}

output "tunnel1_address" {
  description = "Public IP address of VPN tunnel 1"
  value       = aws_vpn_connection.this.tunnel1_address
}

output "tunnel2_address" {
  description = "Public IP address of VPN tunnel 2"
  value       = aws_vpn_connection.this.tunnel2_address
}