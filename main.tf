data "aws_availability_zones" "this" {
  state = "available"
}

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

data "aws_caller_identity" "current" {}

locals {
  azs = slice(data.aws_availability_zones.this.names, 0, var.az_count)
  tags = {
    Project = var.project
  }
}

# --- VPCs ---
module "shared_vpc" {
  source = "./modules/vpc"
  name   = "${var.project}-shared"
  cidr   = var.shared_cidr
  azs    = local.azs
  tags   = local.tags
}

module "app_vpc" {
  source = "./modules/vpc"
  name   = "${var.project}-app"
  cidr   = var.app_cidr
  azs    = local.azs
  tags   = local.tags
}

module "onprem_vpc" {
  source = "./modules/vpc"
  name   = "${var.project}-onprem"
  cidr   = var.onprem_cidr
  azs    = local.azs
  tags   = local.tags
}

# --- Transit Gateway ---
module "tgw" {
  source = "./modules/tgw"
  name   = "${var.project}-tgw"
  tags   = local.tags
}

# Attach VPCs to TGW
resource "aws_ec2_transit_gateway_vpc_attachment" "shared" {
  transit_gateway_id = module.tgw.tgw_id
  vpc_id             = module.shared_vpc.vpc_id
  subnet_ids         = module.shared_vpc.private_subnet_ids
  tags               = merge(local.tags, { Name = "shared-attach" })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "app" {
  transit_gateway_id = module.tgw.tgw_id
  vpc_id             = module.app_vpc.vpc_id
  subnet_ids         = module.app_vpc.private_subnet_ids
  tags               = merge(local.tags, { Name = "app-attach" })
}

resource "aws_ec2_transit_gateway_vpc_attachment" "onprem" {
  transit_gateway_id = module.tgw.tgw_id
  vpc_id             = module.onprem_vpc.vpc_id
  subnet_ids         = module.onprem_vpc.private_subnet_ids
  tags               = merge(local.tags, { Name = "onprem-attach" })
}

# TGW route tables: one shared "core" table is enough for low-cost lab
resource "aws_ec2_transit_gateway_route_table" "core" {
  transit_gateway_id = module.tgw.tgw_id
  tags               = merge(local.tags, { Name = "tgw-core-rt" })
}

# Associate all attachments to core RT
resource "aws_ec2_transit_gateway_route_table_association" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

resource "aws_ec2_transit_gateway_route_table_association" "app" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

resource "aws_ec2_transit_gateway_route_table_association" "onprem" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.onprem.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

# Enable propagation
resource "aws_ec2_transit_gateway_route_table_propagation" "shared" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.shared.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "app" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.app.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "onprem" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.onprem.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

# VPN attachment to TGW and route propagation
resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  transit_gateway_attachment_id  = module.vpn.vpn_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn" {
  transit_gateway_attachment_id  = module.vpn.vpn_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.core.id
}

# Add routes in each VPC route table to point to TGW for other CIDRs
# Shared VPC routes
resource "aws_route" "shared_to_app_via_tgw" {
  route_table_id         = module.shared_vpc.private_route_table_id
  destination_cidr_block = var.app_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

resource "aws_route" "shared_to_onprem_via_tgw" {
  route_table_id         = module.shared_vpc.private_route_table_id
  destination_cidr_block = var.onprem_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

# App VPC routes
resource "aws_route" "app_to_shared_via_tgw" {
  route_table_id         = module.app_vpc.private_route_table_id
  destination_cidr_block = var.shared_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

resource "aws_route" "app_to_onprem_via_tgw" {
  route_table_id         = module.app_vpc.private_route_table_id
  destination_cidr_block = var.onprem_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

# On-prem VPC routes
resource "aws_route" "onprem_to_shared_via_tgw" {
  route_table_id         = module.onprem_vpc.private_route_table_id
  destination_cidr_block = var.shared_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

resource "aws_route" "onprem_to_app_via_tgw" {
  route_table_id         = module.onprem_vpc.private_route_table_id
  destination_cidr_block = var.app_cidr
  transit_gateway_id     = module.tgw.tgw_id
}

# --- VPN Connection to On-Prem ---
module "vpn" {
  source            = "./modules/vpn"
  name              = var.project
  vpc_id            = module.onprem_vpc.vpc_id
  public_subnet_id  = element(module.onprem_vpc.public_subnet_ids, 0)
  onprem_cidr       = var.onprem_cidr
  tgw_id            = module.tgw.tgw_id
  instance_type     = var.instance_type
  vpn_preshared_key_1 = var.vpn_preshared_key_1
  vpn_preshared_key_2 = var.vpn_preshared_key_2
  tags              = local.tags
}

# --- Test Instances (SSM Managed) ---
resource "aws_iam_role" "test_instance_role" {
  name = "${var.project}-test-instance-role"

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

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.test_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "test_instance_profile" {
  name = "${var.project}-test-instance-profile"
  role = aws_iam_role.test_instance_role.name
}

# Bastion in shared VPC
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = element(module.shared_vpc.public_subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.test_instance.id]
  iam_instance_profile   = aws_iam_instance_profile.test_instance_profile.name
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nc bind-utils
  EOF
  
  tags = merge(local.tags, {
    Name = "${var.project}-bastion"
  })
}

# SECURITY GROUP FOR APP SERVER (FIXED: Now in app VPC)
resource "aws_security_group" "app_server" {
  name        = "${var.project}-app-server-sg"
  description = "Security group for app server in app VPC"
  vpc_id      = module.app_vpc.vpc_id

  ingress {
    description = "HTTP from other VPCs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.shared_cidr, var.onprem_cidr]
  }

  ingress {
    description = "ICMP for testing"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.shared_cidr, var.onprem_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project}-app-server-sg" })
}

# App server in app VPC (private) - FIXED: Uses correct security group
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = element(module.app_vpc.private_subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.app_server.id]  # FIXED: Now uses app_vpc security group
  iam_instance_profile   = aws_iam_instance_profile.test_instance_profile.name
  
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nc httpd
    systemctl start httpd
    systemctl enable httpd
    echo "Hello from App Server" > /var/www/html/index.html
  EOF
  
  tags = merge(local.tags, {
    Name = "${var.project}-app-server"
  })
}

# Security Group for test instances in shared VPC
resource "aws_security_group" "test_instance" {
  name        = "${var.project}-test-instance-sg"
  description = "Security group for test instances in shared VPC"
  vpc_id      = module.shared_vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.shared_cidr, var.onprem_cidr]
  }

  ingress {
    description = "ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.shared_cidr, var.app_cidr, var.onprem_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project}-test-instance-sg" })
}

# --- VPC Endpoints (for SSM without NAT) ---
# Shared VPC Endpoints
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.shared_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.shared_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  
  tags = merge(local.tags, { Name = "${var.project}-shared-ssm-endpoint" })
}

# App VPC Endpoints
resource "aws_vpc_endpoint" "app_ssm" {
  vpc_id              = module.app_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.app_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.app_vpc_endpoint.id]
  private_dns_enabled = true
  
  tags = merge(local.tags, { Name = "${var.project}-app-ssm-endpoint" })
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = module.shared_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.shared_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  
  tags = merge(local.tags, { Name = "${var.project}-shared-ssm-messages-endpoint" })
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = module.shared_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.shared_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
  private_dns_enabled = true
  
  tags = merge(local.tags, { Name = "${var.project}-shared-ec2-messages-endpoint" })
}

resource "aws_vpc_endpoint" "app_ssm_messages" {
  vpc_id              = module.app_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.app_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.app_vpc_endpoint.id]
  private_dns_enabled = true
  
  tags = merge(local.tags, { Name = "${var.project}-app-ssm-messages-endpoint" })
}

resource "aws_vpc_endpoint" "app_ec2_messages" {
  vpc_id              = module.app_vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.app_vpc.private_subnet_ids
  security_group_ids  = [aws_security_group.app_vpc_endpoint.id]
  private_dns_enabled = true
  
  tags = merge(local.tags, { Name = "${var.project}-app-ec2-messages-endpoint" })
}

# S3 Gateway Endpoint (FREE)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.shared_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [module.shared_vpc.private_route_table_id]
  
  tags = merge(local.tags, { Name = "${var.project}-shared-s3-endpoint" })
}

resource "aws_vpc_endpoint" "app_s3" {
  vpc_id            = module.app_vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [module.app_vpc.private_route_table_id]
  
  tags = merge(local.tags, { Name = "${var.project}-app-s3-endpoint" })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project}-shared-vpc-endpoint-sg"
  description = "Security group for shared VPC endpoints"
  vpc_id      = module.shared_vpc.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.shared_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project}-shared-vpc-endpoint-sg" })
}

resource "aws_security_group" "app_vpc_endpoint" {
  name        = "${var.project}-app-vpc-endpoint-sg"
  description = "Security group for app VPC endpoints"
  vpc_id      = module.app_vpc.vpc_id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${var.project}-app-vpc-endpoint-sg" })
}

# --- Observability Module ---
module "observability" {
  source = "./modules/observability"
  
  project                 = var.project
  region                 = var.region
  tgw_id                 = module.tgw.tgw_id
  vpn_connection_id      = module.vpn.vpn_connection_id
  vpc_ids                = {
    shared = module.shared_vpc.vpc_id
    app    = module.app_vpc.vpc_id
    onprem = module.onprem_vpc.vpc_id
  }
  flow_log_retention_days = var.flow_log_retention_days
  tags                   = local.tags
}