#!/usr/bin/env python3
"""
AWS Advanced Networking Lab - Professional Architecture Diagram
Uses AWS-style colors and layout for presentations
"""

import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib.patches import FancyBboxPatch, Rectangle, Circle, Polygon
import numpy as np

def create_professional_diagram():
    # Create figure with presentation-friendly size (16:9 aspect ratio)
    fig, ax = plt.subplots(1, 1, figsize=(20, 11.25))
    ax.set_xlim(0, 20)
    ax.set_ylim(0, 11.25)
    ax.axis('off')
    
    # AWS Official Colors
    aws_orange = '#FF9900'
    aws_blue = '#232F3E'
    aws_light_blue = '#4B92DB'
    aws_gray = '#F2F3F3'
    vpc_blue = '#E1F5FE'
    subnet_blue = '#B3E5FC'
    
    # Background
    fig.patch.set_facecolor('white')
    
    # Title Section
    title_box = Rectangle((0, 10), 20, 1.25, facecolor=aws_blue, edgecolor='none')
    ax.add_patch(title_box)
    ax.text(10, 10.6, 'AWS Advanced Networking Lab Architecture', 
            fontsize=24, fontweight='bold', ha='center', color='white')
    ax.text(10, 10.2, 'Hub-and-Spoke with Transit Gateway and Site-to-Site VPN', 
            fontsize=14, ha='center', color=aws_gray)
    
    # AWS Region Container
    region_box = FancyBboxPatch((0.5, 0.5), 19, 9, 
                               boxstyle="round,pad=0.1", 
                               facecolor='#FAFAFA', 
                               edgecolor=aws_blue, 
                               linewidth=2)
    ax.add_patch(region_box)
    ax.text(1, 9.2, 'AWS Region: us-east-1', fontsize=14, fontweight='bold', color=aws_blue)
    
    # Availability Zone indicator
    az_box = Rectangle((1, 8.5), 18, 0.4, facecolor=aws_gray, edgecolor=aws_blue, alpha=0.3)
    ax.add_patch(az_box)
    ax.text(10, 8.7, 'Availability Zone: us-east-1a', fontsize=12, ha='center', color=aws_blue)
    
    # VPC 1: Shared Services VPC
    shared_vpc = FancyBboxPatch((1.5, 5.5), 5, 2.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor=vpc_blue, 
                               edgecolor=aws_light_blue, 
                               linewidth=2)
    ax.add_patch(shared_vpc)
    
    # VPC Icon (simplified AWS VPC representation)
    vpc_icon1 = Circle((2, 7.5), 0.15, facecolor=aws_light_blue, edgecolor=aws_blue, linewidth=2)
    ax.add_patch(vpc_icon1)
    ax.text(2.3, 7.7, 'Shared Services VPC', fontsize=12, fontweight='bold', color=aws_blue)
    ax.text(2.3, 7.4, '10.10.0.0/16', fontsize=10, color=aws_blue)
    
    # Subnets in Shared VPC
    shared_public = Rectangle((2, 6.8), 2, 0.5, facecolor=subnet_blue, edgecolor=aws_light_blue, linewidth=1)
    shared_private = Rectangle((4.2, 6.8), 2, 0.5, facecolor=subnet_blue, edgecolor=aws_light_blue, linewidth=1)
    ax.add_patch(shared_public)
    ax.add_patch(shared_private)
    ax.text(3, 7.05, 'Public Subnet\n10.10.0.0/24', fontsize=9, ha='center', va='center')
    ax.text(5.2, 7.05, 'Private Subnet\n10.10.100.0/24', fontsize=9, ha='center', va='center')
    
    # Bastion Host (EC2 Icon)
    bastion_box = Rectangle((2.8, 6.1), 0.4, 0.3, facecolor=aws_orange, edgecolor=aws_blue, linewidth=1)
    ax.add_patch(bastion_box)
    ax.text(3, 6.25, 'EC2', fontsize=8, ha='center', va='center', color='white', fontweight='bold')
    ax.text(3, 5.9, 'Bastion Host', fontsize=9, ha='center', fontweight='bold')
    
    # VPC Endpoints
    endpoint_positions = [(4.5, 6.1), (4.9, 6.1), (5.3, 6.1)]
    endpoint_labels = ['SSM', 'SSM-Msg', 'EC2-Msg']
    for i, (x, y) in enumerate(endpoint_positions):
        ep_box = Rectangle((x-0.1, y), 0.2, 0.2, facecolor='#9C27B0', edgecolor=aws_blue, linewidth=1)
        ax.add_patch(ep_box)
        ax.text(x, y+0.1, 'VE', fontsize=6, ha='center', va='center', color='white', fontweight='bold')
        ax.text(x, y-0.3, endpoint_labels[i], fontsize=7, ha='center')
    
    # VPC 2: Application VPC
    app_vpc = FancyBboxPatch((7.5, 5.5), 5, 2.5, 
                            boxstyle="round,pad=0.1", 
                            facecolor=vpc_blue, 
                            edgecolor=aws_light_blue, 
                            linewidth=2)
    ax.add_patch(app_vpc)
    
    vpc_icon2 = Circle((8, 7.5), 0.15, facecolor=aws_light_blue, edgecolor=aws_blue, linewidth=2)
    ax.add_patch(vpc_icon2)
    ax.text(8.3, 7.7, 'Application VPC', fontsize=12, fontweight='bold', color=aws_blue)
    ax.text(8.3, 7.4, '10.20.0.0/16', fontsize=10, color=aws_blue)
    
    # Subnets in App VPC
    app_public = Rectangle((8, 6.8), 2, 0.5, facecolor=subnet_blue, edgecolor=aws_light_blue, linewidth=1)
    app_private = Rectangle((10.2, 6.8), 2, 0.5, facecolor=subnet_blue, edgecolor=aws_light_blue, linewidth=1)
    ax.add_patch(app_public)
    ax.add_patch(app_private)
    ax.text(9, 7.05, 'Public Subnet\n10.20.0.0/24', fontsize=9, ha='center', va='center')
    ax.text(11.2, 7.05, 'Private Subnet\n10.20.100.0/24', fontsize=9, ha='center', va='center')
    
    # App Server (EC2 Icon)
    app_server_box = Rectangle((10.8, 6.1), 0.4, 0.3, facecolor=aws_orange, edgecolor=aws_blue, linewidth=1)
    ax.add_patch(app_server_box)
    ax.text(11, 6.25, 'EC2', fontsize=8, ha='center', va='center', color='white', fontweight='bold')
    ax.text(11, 5.9, 'App Server', fontsize=9, ha='center', fontweight='bold')
    
    # VPC Endpoints in App VPC
    for i, (x, y) in enumerate([(8.5, 6.1), (8.9, 6.1), (9.3, 6.1)]):
        ep_box = Rectangle((x-0.1, y), 0.2, 0.2, facecolor='#9C27B0', edgecolor=aws_blue, linewidth=1)
        ax.add_patch(ep_box)
        ax.text(x, y+0.1, 'VE', fontsize=6, ha='center', va='center', color='white', fontweight='bold')
        ax.text(x, y-0.3, endpoint_labels[i], fontsize=7, ha='center')
    
    # VPC 3: On-Premises Simulation VPC
    onprem_vpc = FancyBboxPatch((14, 5.5), 5, 2.5, 
                               boxstyle="round,pad=0.1", 
                               facecolor=vpc_blue, 
                               edgecolor=aws_light_blue, 
                               linewidth=2)
    ax.add_patch(onprem_vpc)
    
    vpc_icon3 = Circle((14.5, 7.5), 0.15, facecolor=aws_light_blue, edgecolor=aws_blue, linewidth=2)
    ax.add_patch(vpc_icon3)
    ax.text(14.8, 7.7, 'On-Premises Simulation VPC', fontsize=12, fontweight='bold', color=aws_blue)
    ax.text(14.8, 7.4, '10.30.0.0/16', fontsize=10, color=aws_blue)
    
    # Subnets in OnPrem VPC
    onprem_public = Rectangle((14.5, 6.8), 2, 0.5, facecolor=subnet_blue, edgecolor=aws_light_blue, linewidth=1)
    onprem_private = Rectangle((16.7, 6.8), 2, 0.5, facecolor=subnet_blue, edgecolor=aws_light_blue, linewidth=1)
    ax.add_patch(onprem_public)
    ax.add_patch(onprem_private)
    ax.text(15.5, 7.05, 'Public Subnet\n10.30.0.0/24', fontsize=9, ha='center', va='center')
    ax.text(17.7, 7.05, 'Private Subnet\n10.30.100.0/24', fontsize=9, ha='center', va='center')
    
    # StrongSwan (Customer Gateway)
    strongswan_box = Rectangle((15.3, 6.1), 0.4, 0.3, facecolor='#E91E63', edgecolor=aws_blue, linewidth=1)
    ax.add_patch(strongswan_box)
    ax.text(15.5, 6.25, 'CGW', fontsize=7, ha='center', va='center', color='white', fontweight='bold')
    ax.text(15.5, 5.9, 'StrongSwan', fontsize=9, ha='center', fontweight='bold')
    ax.text(15.5, 5.7, '54.84.220.170', fontsize=8, ha='center')
    
    # Transit Gateway (Center Hub)
    tgw_circle = Circle((10, 3.5), 0.8, facecolor=aws_orange, edgecolor=aws_blue, linewidth=3)
    ax.add_patch(tgw_circle)
    ax.text(10, 3.7, 'Transit', fontsize=12, ha='center', va='center', color='white', fontweight='bold')
    ax.text(10, 3.3, 'Gateway', fontsize=12, ha='center', va='center', color='white', fontweight='bold')
    ax.text(10, 2.5, 'tgw-02c7208c8a5442572', fontsize=10, ha='center', fontweight='bold')
    
    # Site-to-Site VPN Connection
    vpn_box = FancyBboxPatch((12.5, 2.8), 3, 1.4, 
                            boxstyle="round,pad=0.1", 
                            facecolor='#FF5722', 
                            edgecolor=aws_blue, 
                            linewidth=2)
    ax.add_patch(vpn_box)
    ax.text(14, 3.7, 'Site-to-Site VPN', fontsize=12, ha='center', va='center', color='white', fontweight='bold')
    ax.text(14, 3.3, 'vpn-03b4be9fbe7724aa2', fontsize=10, ha='center', va='center', color='white')
    ax.text(14, 3.0, 'Tunnel 1 & 2', fontsize=9, ha='center', va='center', color='white')
    
    # Internet Gateway
    igw_box = Rectangle((9.2, 1.2), 1.6, 0.6, facecolor=aws_light_blue, edgecolor=aws_blue, linewidth=2)
    ax.add_patch(igw_box)
    ax.text(10, 1.5, 'Internet Gateway', fontsize=10, ha='center', va='center', color='white', fontweight='bold')
    
    # Internet (Cloud)
    internet_points = np.array([[8.5, 0.5], [9.5, 0.8], [10.5, 0.8], [11.5, 0.5], 
                               [11, 0.2], [10, 0.1], [9, 0.2]])
    internet_cloud = Polygon(internet_points, facecolor='#E3F2FD', edgecolor=aws_light_blue, linewidth=2)
    ax.add_patch(internet_cloud)
    ax.text(10, 0.45, 'Internet', fontsize=12, ha='center', va='center', fontweight='bold', color=aws_blue)
    
    # CloudWatch Logs
    logs_box = FancyBboxPatch((1.5, 1.5), 4, 1.5, 
                             boxstyle="round,pad=0.1", 
                             facecolor='#FFF3E0', 
                             edgecolor='#FF9800', 
                             linewidth=2)
    ax.add_patch(logs_box)
    ax.text(3.5, 2.6, 'CloudWatch Logs', fontsize=12, ha='center', fontweight='bold', color='#E65100')
    ax.text(3.5, 2.2, 'VPC Flow Logs', fontsize=10, ha='center', color='#E65100')
    ax.text(3.5, 1.9, '/aws/vpc/flow-logs/', fontsize=9, ha='center', color='#E65100')
    ax.text(3.5, 1.7, 'adv-net-lowcost', fontsize=9, ha='center', color='#E65100')
    
    # Connection Lines (Professional style)
    connection_color = aws_blue
    connection_width = 2
    
    # VPC to TGW connections
    connections = [
        # Shared VPC to TGW
        ([4, 5.5], [8.5, 4.2]),
        # App VPC to TGW  
        ([10, 5.5], [10, 4.3]),
        # OnPrem VPC to TGW
        ([16.5, 5.5], [11.5, 4.2]),
        # TGW to VPN
        ([10.8, 3.5], [12.5, 3.5]),
        # VPN to StrongSwan
        ([15.5, 4.2], [15.5, 5.5]),
        # IGW to Internet
        ([10, 1.8], [10, 0.8]),
        # Flow logs connections (dashed)
        ([3.5, 3], [4, 5.5]),  # To Shared VPC
        ([3.5, 3], [10, 5.5]), # To App VPC
        ([3.5, 3], [16.5, 5.5]) # To OnPrem VPC
    ]
    
    for i, (start, end) in enumerate(connections):
        if i >= len(connections) - 3:  # Last 3 are flow log connections
            ax.plot([start[0], end[0]], [start[1], end[1]], 
                   color='#FF9800', linewidth=1.5, linestyle='--', alpha=0.7)
        else:
            ax.plot([start[0], end[0]], [start[1], end[1]], 
                   color=connection_color, linewidth=connection_width)
            
            # Add arrows for main connections
            if i < 4:
                mid_x = (start[0] + end[0]) / 2
                mid_y = (start[1] + end[1]) / 2
                dx = end[0] - start[0]
                dy = end[1] - start[1]
                length = np.sqrt(dx**2 + dy**2)
                dx_norm = dx / length * 0.2
                dy_norm = dy / length * 0.2
                
                arrow = patches.FancyArrowPatch((mid_x - dx_norm, mid_y - dy_norm),
                                              (mid_x + dx_norm, mid_y + dy_norm),
                                              arrowstyle='->', mutation_scale=15,
                                              color=connection_color, linewidth=2)
                ax.add_patch(arrow)
    
    # Cost Optimization Callout
    cost_box = FancyBboxPatch((16, 1.5), 3.5, 1.5, 
                             boxstyle="round,pad=0.1", 
                             facecolor='#E8F5E8', 
                             edgecolor='#4CAF50', 
                             linewidth=2)
    ax.add_patch(cost_box)
    ax.text(17.75, 2.6, 'Cost Optimized', fontsize=12, ha='center', fontweight='bold', color='#2E7D32')
    ax.text(17.75, 2.2, '• No NAT Gateways', fontsize=9, ha='center', color='#2E7D32')
    ax.text(17.75, 2.0, '• VPC Endpoints Only', fontsize=9, ha='center', color='#2E7D32')
    ax.text(17.75, 1.8, '• t2.micro Instances', fontsize=9, ha='center', color='#2E7D32')
    
    plt.tight_layout()
    return fig

if __name__ == "__main__":
    fig = create_professional_diagram()
    
    # Save high-resolution versions for presentations
    plt.savefig('/home/nana/aws-adv-net-project/aws-architecture-professional.png', 
                dpi=300, bbox_inches='tight', facecolor='white', edgecolor='none')
    
    plt.savefig('/home/nana/aws-adv-net-project/aws-architecture-professional.pdf', 
                format='pdf', bbox_inches='tight', facecolor='white', edgecolor='none')
    
    print("Professional architecture diagrams generated:")
    print("- aws-architecture-professional.png (300 DPI for presentations)")
    print("- aws-architecture-professional.pdf (vector format)")
    
    plt.show()