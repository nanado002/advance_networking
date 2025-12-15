#!/usr/bin/env python3
"""
AWS Advanced Networking Lab - Architecture Diagram Generator
Creates a visual representation of the deployed infrastructure
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, ConnectionPatch
import numpy as np

def create_architecture_diagram():
    fig, ax = plt.subplots(1, 1, figsize=(16, 12))
    ax.set_xlim(0, 16)
    ax.set_ylim(0, 12)
    ax.axis('off')
    
    # Colors
    vpc_color = '#E8F4FD'
    subnet_color = '#D4E6F1'
    tgw_color = '#F8C471'
    vpn_color = '#F1948A'
    instance_color = '#A9DFBF'
    endpoint_color = '#D2B4DE'
    
    # Title
    ax.text(8, 11.5, 'AWS Advanced Networking Lab Architecture', 
            fontsize=18, fontweight='bold', ha='center')
    
    # Region box
    region_box = FancyBboxPatch((0.5, 0.5), 15, 10.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor='#F8F9FA', 
                               edgecolor='#2C3E50', 
                               linewidth=2)
    ax.add_patch(region_box)
    ax.text(1, 10.8, 'AWS Region: us-east-1', fontsize=12, fontweight='bold')
    
    # Shared VPC
    shared_vpc = FancyBboxPatch((1, 7), 4.5, 3.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor=vpc_color, 
                               edgecolor='#3498DB', 
                               linewidth=2)
    ax.add_patch(shared_vpc)
    ax.text(3.25, 10.2, 'Shared VPC', fontsize=12, fontweight='bold', ha='center')
    ax.text(3.25, 9.9, '10.10.0.0/16', fontsize=10, ha='center')
    
    # Shared VPC subnets
    shared_public = patches.Rectangle((1.2, 9), 1.8, 1, facecolor=subnet_color, edgecolor='#2980B9')
    shared_private = patches.Rectangle((3.2, 9), 1.8, 1, facecolor=subnet_color, edgecolor='#2980B9')
    ax.add_patch(shared_public)
    ax.add_patch(shared_private)
    ax.text(2.1, 9.5, 'Public\n10.10.0.0/24', fontsize=9, ha='center', va='center')
    ax.text(4.1, 9.5, 'Private\n10.10.100.0/24', fontsize=9, ha='center', va='center')
    
    # Bastion instance
    bastion = patches.Circle((2.1, 8.3), 0.2, facecolor=instance_color, edgecolor='#27AE60')
    ax.add_patch(bastion)
    ax.text(2.1, 7.9, 'Bastion\ni-0473725c94f4d2b0d', fontsize=8, ha='center')
    
    # VPC Endpoints in shared VPC
    endpoints = [(3.5, 8.3), (3.9, 8.3), (4.3, 8.3)]
    endpoint_labels = ['SSM', 'SSM-Msg', 'EC2-Msg']
    for i, (x, y) in enumerate(endpoints):
        ep = patches.Rectangle((x-0.1, y-0.1), 0.2, 0.2, facecolor=endpoint_color, edgecolor='#8E44AD')
        ax.add_patch(ep)
        ax.text(x, y-0.4, endpoint_labels[i], fontsize=7, ha='center')
    
    # App VPC
    app_vpc = FancyBboxPatch((6, 7), 4.5, 3.5, 
                            boxstyle="round,pad=0.1", 
                            facecolor=vpc_color, 
                            edgecolor='#3498DB', 
                            linewidth=2)
    ax.add_patch(app_vpc)
    ax.text(8.25, 10.2, 'App VPC', fontsize=12, fontweight='bold', ha='center')
    ax.text(8.25, 9.9, '10.20.0.0/16', fontsize=10, ha='center')
    
    # App VPC subnets
    app_public = patches.Rectangle((6.2, 9), 1.8, 1, facecolor=subnet_color, edgecolor='#2980B9')
    app_private = patches.Rectangle((8.2, 9), 1.8, 1, facecolor=subnet_color, edgecolor='#2980B9')
    ax.add_patch(app_public)
    ax.add_patch(app_private)
    ax.text(7.1, 9.5, 'Public\n10.20.0.0/24', fontsize=9, ha='center', va='center')
    ax.text(9.1, 9.5, 'Private\n10.20.100.0/24', fontsize=9, ha='center', va='center')
    
    # App server instance
    app_server = patches.Circle((9.1, 8.3), 0.2, facecolor=instance_color, edgecolor='#27AE60')
    ax.add_patch(app_server)
    ax.text(9.1, 7.9, 'App Server\ni-0fb0ec22102a92543', fontsize=8, ha='center')
    
    # VPC Endpoints in app VPC
    app_endpoints = [(7.5, 8.3), (7.9, 8.3), (8.3, 8.3)]
    for i, (x, y) in enumerate(app_endpoints):
        ep = patches.Rectangle((x-0.1, y-0.1), 0.2, 0.2, facecolor=endpoint_color, edgecolor='#8E44AD')
        ax.add_patch(ep)
        ax.text(x, y-0.4, endpoint_labels[i], fontsize=7, ha='center')
    
    # OnPrem VPC
    onprem_vpc = FancyBboxPatch((11.5, 7), 4, 3.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor=vpc_color, 
                               edgecolor='#3498DB', 
                               linewidth=2)
    ax.add_patch(onprem_vpc)
    ax.text(13.5, 10.2, 'OnPrem VPC', fontsize=12, fontweight='bold', ha='center')
    ax.text(13.5, 9.9, '10.30.0.0/16', fontsize=10, ha='center')
    
    # OnPrem VPC subnets
    onprem_public = patches.Rectangle((11.7, 9), 1.5, 1, facecolor=subnet_color, edgecolor='#2980B9')
    onprem_private = patches.Rectangle((13.5, 9), 1.5, 1, facecolor=subnet_color, edgecolor='#2980B9')
    ax.add_patch(onprem_public)
    ax.add_patch(onprem_private)
    ax.text(12.45, 9.5, 'Public\n10.30.0.0/24', fontsize=9, ha='center', va='center')
    ax.text(14.25, 9.5, 'Private\n10.30.100.0/24', fontsize=9, ha='center', va='center')
    
    # StrongSwan instance
    strongswan = patches.Circle((12.45, 8.3), 0.2, facecolor=instance_color, edgecolor='#27AE60')
    ax.add_patch(strongswan)
    ax.text(12.45, 7.9, 'StrongSwan\ni-004feea49a7f493f1', fontsize=8, ha='center')
    ax.text(12.45, 7.6, 'Public IP:\n54.84.220.170', fontsize=7, ha='center')
    
    # Transit Gateway
    tgw = patches.Circle((8, 5), 0.8, facecolor=tgw_color, edgecolor='#F39C12', linewidth=2)
    ax.add_patch(tgw)
    ax.text(8, 5, 'Transit\nGateway\ntgw-02c7208c8a5442572', fontsize=9, ha='center', va='center', fontweight='bold')
    
    # VPN Connection
    vpn_box = FancyBboxPatch((10.5, 4.2), 3, 1.6, 
                            boxstyle="round,pad=0.1", 
                            facecolor=vpn_color, 
                            edgecolor='#E74C3C', 
                            linewidth=2)
    ax.add_patch(vpn_box)
    ax.text(12, 5, 'Site-to-Site VPN\nvpn-03b4be9fbe7724aa2', fontsize=10, ha='center', va='center', fontweight='bold')
    
    # Internet Gateway
    igw = patches.Rectangle((7.5, 1), 1, 0.8, facecolor='#AED6F1', edgecolor='#3498DB')
    ax.add_patch(igw)
    ax.text(8, 1.4, 'Internet\nGateway', fontsize=9, ha='center', va='center')
    
    # Internet cloud
    internet = patches.Ellipse((8, 0.3), 2, 0.4, facecolor='#E8F8F5', edgecolor='#1ABC9C')
    ax.add_patch(internet)
    ax.text(8, 0.3, 'Internet', fontsize=10, ha='center', va='center', fontweight='bold')
    
    # Connections
    # TGW to VPCs
    connections = [
        ((3.25, 7), (6.5, 5.5)),  # Shared to TGW
        ((8.25, 7), (8, 5.8)),    # App to TGW
        ((13.5, 7), (9.5, 5.5)),  # OnPrem to TGW
        ((8.8, 5), (10.5, 5)),    # TGW to VPN
        ((8, 1.8), (8, 4.2)),     # IGW to TGW area
        ((8, 0.7), (8, 1))        # Internet to IGW
    ]
    
    for start, end in connections:
        line = ConnectionPatch(start, end, "data", "data", 
                             arrowstyle="<->", shrinkA=5, shrinkB=5, 
                             mutation_scale=20, fc="black", lw=2)
        ax.add_patch(line)
    
    # Flow Logs indicator
    flow_logs = FancyBboxPatch((1, 2), 3, 1.5, 
                              boxstyle="round,pad=0.1", 
                              facecolor='#FADBD8', 
                              edgecolor='#E74C3C', 
                              linewidth=1)
    ax.add_patch(flow_logs)
    ax.text(2.5, 2.75, 'VPC Flow Logs\nCloudWatch\n/aws/vpc/flow-logs/\nadv-net-lowcost', 
            fontsize=9, ha='center', va='center')
    
    # Legend
    legend_y = 3.5
    ax.text(12, legend_y + 0.5, 'Legend:', fontsize=12, fontweight='bold')
    
    legend_items = [
        (vpc_color, 'VPC', '#3498DB'),
        (subnet_color, 'Subnet', '#2980B9'),
        (instance_color, 'EC2 Instance', '#27AE60'),
        (tgw_color, 'Transit Gateway', '#F39C12'),
        (vpn_color, 'VPN Connection', '#E74C3C'),
        (endpoint_color, 'VPC Endpoint', '#8E44AD')
    ]
    
    for i, (color, label, edge_color) in enumerate(legend_items):
        y_pos = legend_y - (i * 0.3)
        legend_box = patches.Rectangle((12, y_pos - 0.1), 0.3, 0.2, 
                                     facecolor=color, edgecolor=edge_color)
        ax.add_patch(legend_box)
        ax.text(12.5, y_pos, label, fontsize=9, va='center')
    
    # Key Features text
    features_text = """Key Features:
• Hub-and-spoke architecture via Transit Gateway
• Site-to-Site VPN with StrongSwan (simulated on-premises)
• No NAT Gateways (cost optimized)
• VPC Endpoints for SSM access
• VPC Flow Logs for troubleshooting
• Cross-VPC connectivity testing"""
    
    ax.text(1, 5.5, features_text, fontsize=10, va='top', 
            bbox=dict(boxstyle="round,pad=0.3", facecolor='#F8F9FA', edgecolor='#BDC3C7'))
    
    plt.tight_layout()
    return fig

if __name__ == "__main__":
    fig = create_architecture_diagram()
    
    # Save as PNG
    plt.savefig('/home/nana/aws-adv-net-project/architecture-diagram.png', 
                dpi=300, bbox_inches='tight', facecolor='white')
    
    # Save as SVG for scalability
    plt.savefig('/home/nana/aws-adv-net-project/architecture-diagram.svg', 
                format='svg', bbox_inches='tight', facecolor='white')
    
    print("Architecture diagrams generated:")
    print("- architecture-diagram.png (high-resolution)")
    print("- architecture-diagram.svg (scalable vector)")
    
    plt.show()