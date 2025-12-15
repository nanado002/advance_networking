#!/bin/bash

# AWS Advanced Networking Project Deployment Script
# This script helps manage the low-cost deployment

set -e

PROJECT_NAME="adv-net-lowcost"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to estimate costs
estimate_costs() {
    print_status "Estimated monthly costs (us-east-1):"
    echo "  - Transit Gateway: ~$36/month (24/7)"
    echo "  - VPN Connection: ~$36/month (24/7)"
    echo "  - 3x t2.micro instances: ~$5.40/month (if running 24/7)"
    echo "  - VPC Interface Endpoints (6): ~$64.80/month (24/7)"
    echo "  - VPC Flow Logs: ~$1-5/month (depending on traffic)"
    echo ""
    print_warning "Total estimated: ~$142-147/month if running 24/7"
    print_warning "To minimize costs:"
    echo "  1. Stop EC2 instances when not testing"
    echo "  2. Delete TGW and VPN when done practicing"
    echo "  3. Use 'terraform destroy' to clean up everything"
}

# Function to deploy infrastructure
deploy() {
    print_status "Deploying AWS Advanced Networking Lab..."
    
    # Initialize Terraform
    print_status "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    print_status "Planning deployment..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo ""
    print_warning "This will create billable AWS resources!"
    estimate_costs
    echo ""
    read -p "Do you want to proceed? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Applying Terraform configuration..."
        terraform apply tfplan
        rm tfplan
        
        print_status "Deployment complete!"
        print_status "Getting instance information..."
        terraform output
        
        print_warning "Remember to stop instances when not testing to save costs!"
    else
        print_status "Deployment cancelled."
        rm -f tfplan
    fi
}

# Function to stop instances
stop_instances() {
    print_status "Stopping EC2 instances to save costs..."
    
    BASTION_ID=$(terraform output -raw bastion_instance_id 2>/dev/null || echo "")
    APP_SERVER_ID=$(terraform output -raw app_server_instance_id 2>/dev/null || echo "")
    STRONGSWAN_ID=$(terraform output -raw strongswan_instance_id 2>/dev/null || echo "")
    
    if [[ -n "$BASTION_ID" ]]; then
        aws ec2 stop-instances --instance-ids $BASTION_ID --region $REGION
        print_status "Stopped bastion instance: $BASTION_ID"
    fi
    
    if [[ -n "$APP_SERVER_ID" ]]; then
        aws ec2 stop-instances --instance-ids $APP_SERVER_ID --region $REGION
        print_status "Stopped app server instance: $APP_SERVER_ID"
    fi
    
    if [[ -n "$STRONGSWAN_ID" ]]; then
        aws ec2 stop-instances --instance-ids $STRONGSWAN_ID --region $REGION
        print_status "Stopped StrongSwan instance: $STRONGSWAN_ID"
    fi
}

# Function to start instances
start_instances() {
    print_status "Starting EC2 instances..."
    
    BASTION_ID=$(terraform output -raw bastion_instance_id 2>/dev/null || echo "")
    APP_SERVER_ID=$(terraform output -raw app_server_instance_id 2>/dev/null || echo "")
    STRONGSWAN_ID=$(terraform output -raw strongswan_instance_id 2>/dev/null || echo "")
    
    if [[ -n "$BASTION_ID" ]]; then
        aws ec2 start-instances --instance-ids $BASTION_ID --region $REGION
        print_status "Started bastion instance: $BASTION_ID"
    fi
    
    if [[ -n "$APP_SERVER_ID" ]]; then
        aws ec2 start-instances --instance-ids $APP_SERVER_ID --region $REGION
        print_status "Started app server instance: $APP_SERVER_ID"
    fi
    
    if [[ -n "$STRONGSWAN_ID" ]]; then
        aws ec2 start-instances --instance-ids $STRONGSWAN_ID --region $REGION
        print_status "Started StrongSwan instance: $STRONGSWAN_ID"
    fi
}

# Function to destroy infrastructure
destroy() {
    print_warning "This will destroy ALL resources and you will lose all data!"
    read -p "Are you sure you want to destroy everything? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        print_status "Destroying infrastructure..."
        terraform destroy -auto-approve
        print_status "All resources destroyed!"
    else
        print_status "Destroy cancelled."
    fi
}

# Function to run connectivity tests
test_connectivity() {
    print_status "Running connectivity tests..."
    
    BASTION_ID=$(terraform output -raw bastion_instance_id 2>/dev/null || echo "")
    APP_SERVER_IP=$(terraform output -raw app_server_private_ip 2>/dev/null || echo "")
    
    if [[ -n "$BASTION_ID" && -n "$APP_SERVER_IP" ]]; then
        print_status "Testing connectivity from bastion to app server..."
        aws ssm send-command \
            --instance-ids $BASTION_ID \
            --document-name "AWS-RunShellScript" \
            --parameters "commands=['ping -c 3 $APP_SERVER_IP', 'curl -m 5 http://$APP_SERVER_IP']" \
            --region $REGION
        
        print_status "Command sent. Check SSM console for results."
    else
        print_error "Could not find instance IDs. Make sure infrastructure is deployed."
    fi
}

# Main script logic
case "$1" in
    "deploy")
        deploy
        ;;
    "stop")
        stop_instances
        ;;
    "start")
        start_instances
        ;;
    "destroy")
        destroy
        ;;
    "test")
        test_connectivity
        ;;
    "costs")
        estimate_costs
        ;;
    *)
        echo "Usage: $0 {deploy|stop|start|destroy|test|costs}"
        echo ""
        echo "Commands:"
        echo "  deploy  - Deploy the infrastructure"
        echo "  stop    - Stop EC2 instances to save costs"
        echo "  start   - Start EC2 instances"
        echo "  destroy - Destroy all infrastructure"
        echo "  test    - Run connectivity tests"
        echo "  costs   - Show cost estimates"
        exit 1
        ;;
esac