output "bastion_instance_id" {
  description = "ID of the bastion instance (for SSM)"
  value       = aws_instance.bastion.id
}

output "app_server_instance_id" {
  description = "ID of the app server instance (for SSM)"
  value       = aws_instance.app_server.id
}

output "strongswan_instance_id" {
  description = "ID of the StrongSwan instance (for SSM)"
  value       = module.vpn.strongswan_instance_id
}

output "strongswan_public_ip" {
  description = "Public IP of the StrongSwan instance"
  value       = module.vpn.strongswan_public_ip
}

output "vpn_connection_id" {
  description = "ID of the VPN connection"
  value       = module.vpn.vpn_connection_id
}

output "tgw_id" {
  description = "Transit Gateway ID"
  value       = module.tgw.tgw_id
}

output "vpc_ids" {
  description = "Map of VPC IDs"
  value = {
    shared = module.shared_vpc.vpc_id
    app    = module.app_vpc.vpc_id
    onprem = module.onprem_vpc.vpc_id
  }
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch Log Group for VPC Flow Logs"
  value       = module.observability.cloudwatch_log_group_name
}

output "ssm_connect_commands" {
  description = "Commands to connect to instances via SSM Session Manager"
  value       = <<-EOT
    # Connect to bastion:
    aws ssm start-session --target ${aws_instance.bastion.id}
    
    # Connect to app server:
    aws ssm start-session --target ${aws_instance.app_server.id}
    
    # Connect to StrongSwan:
    aws ssm start-session --target ${module.vpn.strongswan_instance_id}
  EOT
}
