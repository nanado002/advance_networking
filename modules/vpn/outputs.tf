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