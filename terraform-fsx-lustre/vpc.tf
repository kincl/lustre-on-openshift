# VPC
resource "aws_vpc" "fsx_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Subnet for FSx Lustre
resource "aws_subnet" "fsx_subnet" {
  vpc_id            = aws_vpc.fsx_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "${var.project_name}-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.fsx_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route Table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.fsx_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.fsx_subnet.id
  route_table_id = aws_route_table.rt.id
}

# Security Group for FSx
resource "aws_security_group" "fsx_sg" {
  name        = "${var.project_name}-fsx-sg"
  description = "Security group for FSx Lustre file system"
  vpc_id      = aws_vpc.fsx_vpc.id

  # Allow all traffic from within the VPC
  ingress {
    description = "Allow all traffic from VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  # If peering with another VPC, also allow traffic from the peered VPC
  dynamic "ingress" {
    for_each = var.existing_vpc_id != "" ? [1] : []
    content {
      description = "Allow traffic from peered VPC"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [data.aws_vpc.peer_vpc[0].cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-fsx-sg"
  }
}

# Data source to get information about the existing VPC
data "aws_vpc" "peer_vpc" {
  count = var.existing_vpc_id != "" ? 1 : 0
  id    = var.existing_vpc_id
}

# VPC Peering Connection
resource "aws_vpc_peering_connection" "peer" {
  count       = var.existing_vpc_id != "" ? 1 : 0
  vpc_id      = aws_vpc.fsx_vpc.id
  peer_vpc_id = var.existing_vpc_id
  auto_accept = true

  tags = {
    Name = "${var.project_name}-vpc-peering"
  }
}

# Route to peered VPC in the FSx VPC route table
resource "aws_route" "route_to_peer" {
  count                     = var.existing_vpc_id != "" ? 1 : 0
  route_table_id            = aws_route_table.rt.id
  destination_cidr_block    = data.aws_vpc.peer_vpc[0].cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[0].id
}

# Data source to get main route table of the existing VPC
data "aws_route_tables" "peer_vpc_route_tables" {
  count  = var.existing_vpc_id != "" ? 1 : 0
  vpc_id = var.existing_vpc_id
}

# Route from peered VPC to FSx VPC
resource "aws_route" "route_from_peer" {
  for_each                  = var.existing_vpc_id != "" ? toset(data.aws_route_tables.peer_vpc_route_tables[0].ids) : []
  route_table_id            = each.value
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.peer[0].id
}
