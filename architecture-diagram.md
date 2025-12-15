# AWS Advanced Networking Lab - Architecture Diagram

## Professional Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                    AWS Advanced Networking Lab Architecture                              │
│                Hub-and-Spoke with Transit Gateway and Site-to-Site VPN                  │
└─────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────────────────┐
│  AWS Region: us-east-1                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────────────────┐ │
│  │                        Availability Zone: us-east-1a                               │ │
│  └─────────────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                         │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────────────────┐  │
│  │  Shared VPC     │    │  Application    │    │  On-Premises Simulation VPC        │  │
│  │  10.10.0.0/16   │    │  VPC            │    │  10.30.0.0/16                      │  │
│  │                 │    │  10.20.0.0/16   │    │                                     │  │
│  │ ┌─────┐ ┌─────┐ │    │ ┌─────┐ ┌─────┐ │    │ ┌─────┐ ┌─────────────────────────┐ │  │
│  │ │Pub  │ │Priv │ │    │ │Pub  │ │Priv │ │    │ │Pub  │ │Priv                     │ │  │
│  │ │.0/24│ │.100 │ │    │ │.0/24│ │.100 │ │    │ │.0/24│ │.100/24                  │ │  │
│  │ │     │ │/24  │ │    │ │     │ │/24  │ │    │ │     │ │                         │ │  │
│  │ │     │ │     │ │    │ │     │ │     │ │    │ │     │ │                         │ │  │
│  │ │[EC2]│ │[VE] │ │    │ │     │ │[EC2]│ │    │ │[CGW]│ │                         │ │  │
│  │ │Bast │ │SSM  │ │    │ │     │ │App  │ │    │ │Strng│ │                         │ │  │
│  │ │ion  │ │Endp │ │    │ │     │ │Srvr │ │    │ │Swan │ │                         │ │  │
│  │ └─────┘ └─────┘ │    │ └─────┘ └─────┘ │    │ └─────┘ └─────────────────────────┘ │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────────────────────────┘  │
│           │                       │                              │                      │
│           └───────────────────────┼──────────────────────────────┘                      │
│                                   │                                                     │
│                    ┌──────────────────────────┐                                        │
│                    │     Transit Gateway      │                                        │
│                    │   tgw-02c7208c8a5442572  │◄──────────────────────┐                │
│                    └──────────────────────────┘                       │                │
│                                   │                                    │                │
│                                   │            ┌─────────────────────────────────────┐ │
│                                   │            │      Site-to-Site VPN              │ │
│                                   │            │   vpn-03b4be9fbe7724aa2            │ │
│                                   │            │   Tunnel 1 & 2                     │ │
│                                   │            └─────────────────────────────────────┘ │
│                                   │                                                     │
│                    ┌──────────────────────────┐                                        │
│                    │    Internet Gateway      │                                        │
│                    └──────────────────────────┘                                        │
│                                   │                                                     │
│                              ┌─────────┐                                               │
│                              │Internet │                                               │
│                              └─────────┘                                               │
│                                                                                         │
│  ┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐   │
│  │        CloudWatch Logs              │    │        Cost Optimized               │   │
│  │                                     │    │                                     │   │
│  │  VPC Flow Logs                      │    │  • No NAT Gateways                 │   │
│  │  /aws/vpc/flow-logs/adv-net-lowcost │    │  • VPC Endpoints Only              │   │
│  │                                     │    │  • t2.micro Instances              │   │
│  │  ┌─ Shared VPC                      │    │  • 7-day log retention             │   │
│  │  ├─ Application VPC                 │    │                                     │   │
│  │  └─ OnPrem VPC                      │    │  Est. Cost: ~$142/month (24/7)     │   │
│  └─────────────────────────────────────┘    └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Component Details

### **VPCs and Networking**
- **Shared Services VPC (10.10.0.0/16)**
  - Public Subnet: 10.10.0.0/24 (Bastion Host)
  - Private Subnet: 10.10.100.0/24 (VPC Endpoints)
  - Bastion: `i-0473725c94f4d2b0d`

- **Application VPC (10.20.0.0/16)**
  - Public Subnet: 10.20.0.0/24 (Future use)
  - Private Subnet: 10.20.100.0/24 (App Server)
  - App Server: `i-0fb0ec22102a92543` (IP: 10.20.100.24)

- **On-Premises Simulation VPC (10.30.0.0/16)**
  - Public Subnet: 10.30.0.0/24 (StrongSwan)
  - Private Subnet: 10.30.100.0/24 (Future use)
  - StrongSwan: `i-004feea49a7f493f1` (Public IP: 54.84.220.170)

### **Transit Gateway Hub**
- **Transit Gateway**: `tgw-02c7208c8a5442572`
- **Route Table**: Single shared route table with propagation
- **Attachments**: 3 VPC attachments + 1 VPN attachment
- **Routing**: Full mesh connectivity between all VPCs

### **Site-to-Site VPN**
- **VPN Connection**: `vpn-03b4be9fbe7724aa2`
- **Customer Gateway**: StrongSwan on EC2 (BGP ASN: 65000)
- **Tunnels**: Dual redundant tunnels with pre-shared keys
- **Routing**: BGP-based dynamic routing

### **Security & Access**
- **VPC Endpoints**: SSM, SSM Messages, EC2 Messages (Interface)
- **S3 Endpoints**: Gateway endpoints (free)
- **Security Groups**: Least privilege access
- **SSM Session Manager**: No SSH/RDP required

### **Monitoring & Logging**
- **VPC Flow Logs**: All VPCs → CloudWatch Logs
- **Log Group**: `/aws/vpc/flow-logs/adv-net-lowcost`
- **Retention**: 7 days (cost optimized)
- **Transit Gateway Flow Logs**: Available for advanced troubleshooting

## Key Features for AWS ANS-C01 Exam

### **Hub-and-Spoke Architecture**
✅ Transit Gateway as central hub  
✅ Multiple VPC attachments  
✅ Route table associations and propagations  
✅ Cross-VPC connectivity without VPC peering  

### **Hybrid Connectivity**
✅ Site-to-Site VPN configuration  
✅ Customer Gateway setup  
✅ BGP routing vs static routes  
✅ VPN tunnel redundancy  

### **Cost Optimization**
✅ No NAT Gateways (saves ~$45/month per AZ)  
✅ VPC Endpoints instead of internet routing  
✅ t2.micro instances (free tier eligible)  
✅ Optimized log retention periods  

### **Network Troubleshooting**
✅ VPC Flow Logs for packet analysis  
✅ Transit Gateway route tables  
✅ VPC Reachability Analyzer ready  
✅ Security group and NACL analysis  

### **Security Best Practices**
✅ Private subnet placement  
✅ SSM Session Manager (no SSH)  
✅ VPC endpoints for AWS service access  
✅ Least privilege security groups  

## Testing Scenarios

1. **Cross-VPC Connectivity**: Bastion → App Server
2. **VPN Connectivity**: StrongSwan → AWS resources
3. **Route Propagation**: BGP vs static routing
4. **Flow Log Analysis**: Packet tracing and troubleshooting
5. **Reachability Testing**: End-to-end connectivity validation

## Deployment Commands

```bash
# Deploy infrastructure
terraform apply

# Test connectivity
./test-connectivity.sh

# Connect via SSM
aws ssm start-session --target i-0473725c94f4d2b0d

# Cost management
./deploy.sh stop    # Stop instances
./deploy.sh start   # Start instances
./deploy.sh destroy # Clean up everything
```

This architecture provides a comprehensive lab environment for AWS Advanced Networking Specialty certification preparation, covering all major exam topics while maintaining cost efficiency.