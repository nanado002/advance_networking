#!/bin/bash

# Connectivity Testing Script for AWS Advanced Networking Lab
# Tests reachability between VPCs through Transit Gateway

set -e

REGION="us-east-1"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get instance IDs and IPs from Terraform output
get_terraform_outputs() {
    BASTION_ID=$(terraform output -raw bastion_instance_id 2>/dev/null || echo "")
    APP_SERVER_ID=$(terraform output -raw app_server_instance_id 2>/dev/null || echo "")
    STRONGSWAN_ID=$(terraform output -raw strongswan_instance_id 2>/dev/null || echo "")
    
    APP_SERVER_IP=$(terraform output -raw app_server_private_ip 2>/dev/null || echo "")
    STRONGSWAN_PRIVATE_IP=$(terraform output -raw strongswan_private_ip 2>/dev/null || echo "")
    
    if [[ -z "$BASTION_ID" || -z "$APP_SERVER_ID" || -z "$STRONGSWAN_ID" ]]; then
        print_error "Could not get instance IDs from Terraform. Make sure infrastructure is deployed."
        exit 1
    fi
}

# Wait for SSM command to complete and get results
wait_for_command() {
    local command_id=$1
    local max_wait=60
    local wait_time=0
    
    while [[ $wait_time -lt $max_wait ]]; do
        status=$(aws ssm get-command-invocation \
            --command-id "$command_id" \
            --instance-id "$BASTION_ID" \
            --region "$REGION" \
            --query 'Status' \
            --output text 2>/dev/null || echo "InProgress")
        
        if [[ "$status" == "Success" ]]; then
            aws ssm get-command-invocation \
                --command-id "$command_id" \
                --instance-id "$BASTION_ID" \
                --region "$REGION" \
                --query 'StandardOutputContent' \
                --output text
            return 0
        elif [[ "$status" == "Failed" ]]; then
            print_error "Command failed"
            aws ssm get-command-invocation \
                --command-id "$command_id" \
                --instance-id "$BASTION_ID" \
                --region "$REGION" \
                --query 'StandardErrorContent' \
                --output text
            return 1
        fi
        
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    print_warning "Command timed out"
    return 1
}

# Test connectivity from bastion to app server
test_bastion_to_app() {
    print_status "Testing connectivity from Bastion (Shared VPC) to App Server (App VPC)..."
    
    command_id=$(aws ssm send-command \
        --instance-ids "$BASTION_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=['echo \"=== Ping Test ===\"', 'ping -c 3 $APP_SERVER_IP', 'echo \"=== HTTP Test ===\"', 'curl -m 10 http://$APP_SERVER_IP || echo \"HTTP test failed\"', 'echo \"=== Route Check ===\"', 'ip route get $APP_SERVER_IP']" \
        --region "$REGION" \
        --query 'Command.CommandId' \
        --output text)
    
    wait_for_command "$command_id"
}

# Test connectivity from bastion to strongswan
test_bastion_to_strongswan() {
    print_status "Testing connectivity from Bastion (Shared VPC) to StrongSwan (OnPrem VPC)..."
    
    command_id=$(aws ssm send-command \
        --instance-ids "$BASTION_ID" \
        --document-name "AWS-RunShellScript" \
        --parameters "commands=['echo \"=== Ping Test ===\"', 'ping -c 3 $STRONGSWAN_PRIVATE_IP', 'echo \"=== Route Check ===\"', 'ip route get $STRONGSWAN_PRIVATE_IP']" \
        --region "$REGION" \
        --query 'Command.CommandId' \
        --output text)
    
    wait_for_command "$command_id"
}

# Test VPN status
test_vpn_status() {
    print_status "Checking VPN Connection Status..."
    
    VPN_ID=$(terraform output -raw vpn_connection_id 2>/dev/null || echo "")
    
    if [[ -n "$VPN_ID" ]]; then
        aws ec2 describe-vpn-connections \
            --vpn-connection-ids "$VPN_ID" \
            --region "$REGION" \
            --query 'VpnConnections[0].VgwTelemetry[*].{Tunnel:OutsideIpAddress,Status:Status,StatusMessage:StatusMessage}' \
            --output table
    else
        print_error "Could not get VPN connection ID"
    fi
}

# Check Transit Gateway route tables
check_tgw_routes() {
    print_status "Checking Transit Gateway Route Tables..."
    
    TGW_ID=$(terraform output -raw transit_gateway_id 2>/dev/null || echo "")
    
    if [[ -n "$TGW_ID" ]]; then
        # Get route table ID
        RT_ID=$(aws ec2 describe-transit-gateway-route-tables \
            --filters "Name=transit-gateway-id,Values=$TGW_ID" \
            --region "$REGION" \
            --query 'TransitGatewayRouteTables[0].TransitGatewayRouteTableId' \
            --output text)
        
        if [[ -n "$RT_ID" && "$RT_ID" != "None" ]]; then
            print_status "Transit Gateway Routes:"
            aws ec2 search-transit-gateway-routes \
                --transit-gateway-route-table-id "$RT_ID" \
                --filters "Name=state,Values=active" \
                --region "$REGION" \
                --query 'Routes[*].{CIDR:DestinationCidrBlock,Type:Type,State:State}' \
                --output table
        fi
    else
        print_error "Could not get Transit Gateway ID"
    fi
}

# Run VPC Reachability Analyzer
run_reachability_test() {
    print_status "Running VPC Reachability Analyzer (if available)..."
    
    # This requires the instances to be running and may incur small charges
    print_warning "Reachability Analyzer tests incur small charges (~$0.10 per test)"
    read -p "Do you want to run reachability tests? (yes/no): " confirm
    
    if [[ $confirm == "yes" ]]; then
        # Create reachability test from bastion to app server
        aws ec2 create-network-insights-path \
            --source "$BASTION_ID" \
            --destination "$APP_SERVER_ID" \
            --protocol tcp \
            --destination-port 80 \
            --region "$REGION" \
            --tag-specifications "ResourceType=network-insights-path,Tags=[{Key=Name,Value=bastion-to-app-test}]" \
            --query 'NetworkInsightsPath.NetworkInsightsPathId' \
            --output text > /tmp/path_id.txt
        
        if [[ -s /tmp/path_id.txt ]]; then
            PATH_ID=$(cat /tmp/path_id.txt)
            print_status "Created reachability path: $PATH_ID"
            
            # Start analysis
            ANALYSIS_ID=$(aws ec2 start-network-insights-analysis \
                --network-insights-path-id "$PATH_ID" \
                --region "$REGION" \
                --query 'NetworkInsightsAnalysis.NetworkInsightsAnalysisId' \
                --output text)
            
            print_status "Started analysis: $ANALYSIS_ID"
            print_status "Check AWS Console for results, or run:"
            echo "aws ec2 describe-network-insights-analyses --network-insights-analysis-ids $ANALYSIS_ID --region $REGION"
        fi
    fi
}

# Main test execution
main() {
    print_status "Starting AWS Advanced Networking Lab Connectivity Tests"
    echo "=================================================="
    
    get_terraform_outputs
    
    print_status "Instance Information:"
    echo "  Bastion ID: $BASTION_ID"
    echo "  App Server ID: $APP_SERVER_ID (IP: $APP_SERVER_IP)"
    echo "  StrongSwan ID: $STRONGSWAN_ID (IP: $STRONGSWAN_PRIVATE_IP)"
    echo ""
    
    # Run tests
    test_bastion_to_app
    echo ""
    
    test_bastion_to_strongswan
    echo ""
    
    test_vpn_status
    echo ""
    
    check_tgw_routes
    echo ""
    
    run_reachability_test
    
    print_status "Testing complete!"
}

# Run main function
main