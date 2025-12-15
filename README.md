# AWS Advanced Networking Lab - Low Cost Version

This project implements a comprehensive AWS networking lab for the Advanced Networking Specialty certification, designed to minimize costs while covering key exam topics.

## Architecture Overview

- **3 VPCs**: Shared (bastion), App (private workload), OnPrem (simulated on-premises)
- **Transit Gateway**: Hub-and-spoke connectivity
- **Site-to-Site VPN**: AWS VPN to StrongSwan instance (simulates on-premises)
- **No NAT Gateways**: Uses VPC endpoints for AWS service access
- **Flow Logs**: VPC and Transit Gateway logging for troubleshooting
- **SSM Access**: Manage instances without SSH/RDP

## Cost Optimization Features

- Uses t2.micro instances (free tier eligible)
- No NAT Gateways (saves ~$45/month per AZ)
- VPC endpoints only where needed
- Automated start/stop scripts for instances
- CloudWatch log retention set to 7 days

## Estimated Monthly Costs (us-east-1)

| Resource | Cost (24/7) | Cost (8hrs/day) |
|----------|-------------|-----------------|
| Transit Gateway | ~$36 | ~$36 |
| VPN Connection | ~$36 | ~$36 |
| 3x t2.micro instances | ~$5.40 | ~$1.80 |
| 6x VPC Interface Endpoints | ~$64.80 | ~$64.80 |
| VPC Flow Logs | ~$1-5 | ~$1-5 |
| **Total** | **~$142-147** | **~$138-142** |

> **Cost Control**: Use `./deploy.sh stop` to stop instances when not testing!

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.5.0
- Bash shell

### Deploy Infrastructure
```bash
# Clone and navigate to project
cd aws-adv-net-project

# Review and customize variables if needed
vim terraform.tfvars

# Deploy with cost estimation
./deploy.sh deploy
```

### Test Connectivity
```bash
# Run comprehensive connectivity tests
./test-connectivity.sh

# Or run specific tests via SSM
aws ssm start-session --target $(terraform output -raw bastion_instance_id)
```

### Cost Management
```bash
# Stop instances to save money
./deploy.sh stop

# Start instances for testing
./deploy.sh start

# Check cost estimates
./deploy.sh costs

# Destroy everything when done
./deploy.sh destroy
```

## Key Learning Topics Covered

### Transit Gateway
- Hub-and-spoke architecture
- Route table associations and propagations
- VPC attachments
- VPN attachments
- Route propagation vs static routes

### VPN Connectivity
- Site-to-Site VPN configuration
- Customer Gateway setup
- StrongSwan configuration
- BGP vs static routing
- Tunnel redundancy

### Routing & Reachability
- VPC route tables
- Transit Gateway route tables
- Route propagation
- Asymmetric routing troubleshooting
- VPC Reachability Analyzer

### Observability
- VPC Flow Logs
- Transit Gateway Flow Logs
- CloudWatch integration
- Network troubleshooting

### Security
- Security Groups
- NACLs (if implemented)
- VPC endpoints for secure AWS service access
- SSM Session Manager

## Testing Scenarios

### 1. Basic Connectivity
```bash
# From bastion, test app server
ping 10.20.100.4  # App server private IP
curl http://10.20.100.4

# Test on-premises simulation
ping 10.30.100.4  # StrongSwan private IP
```

### 2. VPN Testing
```bash
# Check VPN status
aws ec2 describe-vpn-connections --vpn-connection-ids $(terraform output -raw vpn_connection_id)

# Test from StrongSwan to AWS resources
aws ssm start-session --target $(terraform output -raw strongswan_instance_id)
ping 10.10.100.4  # Bastion
ping 10.20.100.4  # App server
```

### 3. Flow Log Analysis
```bash
# View flow logs in CloudWatch
aws logs describe-log-streams --log-group-name "/aws/vpc/flow-logs/adv-net-lowcost"

# Filter for specific traffic
aws logs filter-log-events \
  --log-group-name "/aws/vpc/flow-logs/adv-net-lowcost" \
  --filter-pattern "{ $.dstaddr = \"10.20.100.4\" }"
```

### 4. Route Table Analysis
```bash
# Check Transit Gateway routes
./test-connectivity.sh

# Or manually:
TGW_RT_ID=$(aws ec2 describe-transit-gateway-route-tables \
  --filters "Name=transit-gateway-id,Values=$(terraform output -raw transit_gateway_id)" \
  --query 'TransitGatewayRouteTables[0].TransitGatewayRouteTableId' --output text)

aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id $TGW_RT_ID \
  --filters "Name=state,Values=active"
```

## Troubleshooting Common Issues

### VPN Not Connecting
1. Check security groups allow UDP 500/4500
2. Verify StrongSwan configuration
3. Check AWS VPN tunnel status
4. Verify BGP/static routes

### Instance SSM Access Issues
1. Ensure VPC endpoints are created
2. Check security group allows HTTPS (443) to VPC endpoints
3. Verify IAM instance profile has SSM permissions
4. Check route tables point to VPC endpoints

### Cross-VPC Connectivity Issues
1. Verify Transit Gateway attachments
2. Check route table associations
3. Verify route propagation is enabled
4. Check security groups allow traffic
5. Use VPC Flow Logs to trace packets

## File Structure

```
aws-adv-net-project/
├── main.tf                 # Main infrastructure
├── variables.tf            # Input variables
├── outputs.tf             # Output values
├── providers.tf           # Provider configuration
├── terraform.tfvars       # Variable values
├── deploy.sh              # Deployment automation
├── test-connectivity.sh   # Testing automation
├── README.md              # This file
└── modules/
    ├── vpc/               # VPC module
    ├── tgw/               # Transit Gateway module
    ├── vpn/               # VPN and StrongSwan module
    └── observability/     # Flow logs and monitoring
```

## Exam Preparation Tips

1. **Practice Route Troubleshooting**: Use flow logs to trace packet paths
2. **Understand BGP vs Static**: Test both routing methods
3. **Security Group Rules**: Practice allowing specific traffic patterns
4. **VPC Endpoints**: Understand when and why to use them
5. **Cost Optimization**: Know when to use NAT Gateway vs VPC endpoints
6. **Reachability Analyzer**: Practice using it for troubleshooting

## Cleanup

Always clean up resources when done to avoid charges:

```bash
# Stop instances first (optional, for gradual cleanup)
./deploy.sh stop

# Destroy all resources
./deploy.sh destroy

# Verify cleanup in AWS Console
```

## Support

For issues or questions:
1. Check AWS CloudFormation/Terraform state
2. Review VPC Flow Logs
3. Use AWS Reachability Analyzer
4. Check security group and route table configurations

## License

This project is for educational purposes for AWS Advanced Networking Specialty certification preparation.