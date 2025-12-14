# AWS Advanced Networking Lab - TGW Hub-and-Spoke with VPN

This Terraform project creates a complete AWS networking lab for Advanced Networking Specialty exam preparation.

## Architecture
- 1 Transit Gateway (TGW) in hub-and-spoke configuration
- 3 VPCs: shared, app, and on-prem simulation
- Site-to-Site VPN from TGW to StrongSwan instance in on-prem VPC
- SSM-managed test instances (no SSH keys required)
- Complete observability stack (Flow Logs, CloudWatch Alarms)

## Cost Control Features
- Uses t2.micro instances
- No NAT Gateway (uses VPC Endpoints instead)
- Instances can be stopped when not testing
- Delete resources with `terraform destroy` when done

## Deployment

### Prerequisites
1. AWS CLI configured with appropriate credentials
2. Terraform 1.5.0 or higher
3. AWS account with permissions to create the resources

### Steps
1. Clone the repository
2. Initialize Terraform:
   ```bash
   terraform init