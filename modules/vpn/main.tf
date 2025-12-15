data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for StrongSwan instance
resource "aws_security_group" "strongswan" {
  name        = "${var.name}-strongswan-sg"
  description = "Security group for StrongSwan VPN server"
  vpc_id      = var.vpc_id

  ingress {
    description = "IKE"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "IPSec NAT-T"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-strongswan-sg" })
}

# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  name = "${var.name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_managed" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.name}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

# StrongSwan User Data
locals {
  strongswan_user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y strongswan awscli jq
    
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    
    mkdir -p /etc/strongswan/ipsec.d
    
    cat > /etc/strongswan/ipsec.conf <<'IPSEC_CONF'
    config setup
        charondebug="ike 2, knl 2, cfg 2"
        uniqueids=no
    
    conn %default
        ikelifetime=8h
        keylife=1h
        rekeymargin=3m
        keyingtries=%forever
        keyexchange=ikev2
        authby=secret
        mobike=no
    
    conn aws-tunnel1
        left=%defaultroute
        leftid=%any
        leftsubnet=${var.onprem_cidr}
        right=%any
        rightsubnet=10.10.0.0/16,10.20.0.0/16
        auto=start
        ike=aes256-sha256-modp2048!
        esp=aes256-sha256-modp2048!
    
    conn aws-tunnel2
        also=aws-tunnel1
    IPSEC_CONF
    
    cat > /etc/strongswan/ipsec.secrets <<'SECRETS'
    # VPN secrets will be configured after VPN creation
    SECRETS
    
    systemctl enable strongswan
    systemctl start strongswan
    
    # Enable IP masquerading
    iptables -t nat -A POSTROUTING -s 10.10.0.0/16 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 10.20.0.0/16 -j MASQUERADE
    iptables -t nat -A POSTROUTING -s 10.30.0.0/16 -j MASQUERADE
    EOF
}

resource "aws_instance" "strongswan" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.strongswan.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name
  user_data_base64       = base64encode(local.strongswan_user_data)
  
  tags = merge(var.tags, {
    Name = "${var.name}-strongswan"
  })
  
  associate_public_ip_address = true
}

# Customer Gateway
resource "aws_customer_gateway" "this" {
  bgp_asn    = 65000
  ip_address = aws_instance.strongswan.public_ip
  type       = "ipsec.1"
  
  tags = merge(var.tags, {
    Name = "${var.name}-cgw"
  })
  
  depends_on = [aws_instance.strongswan]
}

# VPN Connection
resource "aws_vpn_connection" "this" {
  transit_gateway_id      = var.tgw_id
  customer_gateway_id     = aws_customer_gateway.this.id
  type                    = "ipsec.1"
  static_routes_only      = false
  
  tags = merge(var.tags, {
    Name = "${var.name}-vpn"
  })
  
  tunnel1_inside_cidr   = "169.254.100.0/30"
  tunnel2_inside_cidr   = "169.254.200.0/30"
  tunnel1_preshared_key = var.vpn_preshared_key_1
  tunnel2_preshared_key = var.vpn_preshared_key_2
}

# Configure StrongSwan with VPN details after creation
resource "null_resource" "configure_strongswan" {
  depends_on = [aws_vpn_connection.this]
  
  provisioner "local-exec" {
    command = <<-EOF
      aws ssm send-command \
        --instance-ids ${aws_instance.strongswan.id} \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=[
          "cat > /etc/strongswan/ipsec.secrets <<SECRETS",
          "${aws_vpn_connection.this.tunnel1_address} : PSK \"${var.vpn_preshared_key_1}\"",
          "${aws_vpn_connection.this.tunnel2_address} : PSK \"${var.vpn_preshared_key_2}\"",
          "SECRETS",
          "systemctl restart strongswan"
        ]'
    EOF
  }
  
  triggers = {
    vpn_connection_id = aws_vpn_connection.this.id
  }
}