##### VPCs #####

resource "aws_vpc" "primary_vpc" {
  cidr_block           = var.primary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC1"
  }
}

resource "aws_vpc" "secondary_vpc" {
  cidr_block           = var.secondary_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "VPC2"
  }
}

##### SUBNETS #####

resource "aws_subnet" "primary_subnet" {
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.primary_subnet_cidr
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet1"
  }
}

resource "aws_subnet" "secondary_subnet" {
  vpc_id                  = aws_vpc.secondary_vpc.id
  cidr_block              = var.secondary_subnet_cidr
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet2"
  }
}

##### INTERNET GATEWAYS AND ROUTE TABLES #####

resource "aws_internet_gateway" "primary_igw" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "IGW1"
  }
}

resource "aws_internet_gateway" "secondary_igw" {
  vpc_id = aws_vpc.secondary_vpc.id

  tags = {
    Name = "IGW2"
  }
}

resource "aws_route_table" "primary_route_table" {
  vpc_id = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
    Name = "RT1"
  }
}

resource "aws_route_table_association" "primary_route_table_association" {
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_route_table.id
}

resource "aws_route_table" "secondary_route_table" {
  vpc_id = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
    Name = "RT2"
  }
}

resource "aws_route_table_association" "secondary_route_table_association" {
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_route_table.id
}

##### VPC PEERING CONNECTION & ROUTE UPDATE #####

resource "aws_vpc_peering_connection" "primary_to_secondary_vpc_peering" {
  vpc_id      = aws_vpc.primary_vpc.id
  peer_vpc_id = aws_vpc.secondary_vpc.id
  peer_region = var.region
  auto_accept = false


  tags = {
    Name = "VPC1 <> VPC2"
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "secondary_vpc_peering_accepter" {
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_vpc_peering.id
  auto_accept               = true

  tags = {
    Name = "VPC1 <> VPC2"
    Side = "Accepter"
  }
}

resource "aws_route" "primary_to_secondary_vpc_peering_route" {
  route_table_id            = aws_route_table.primary_route_table.id
  destination_cidr_block    = var.secondary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_vpc_peering.id
  depends_on                = [aws_vpc_peering_connection_accepter.secondary_vpc_peering_accepter]
}

resource "aws_route" "secondary_to_primary_vpc_peering_route" {
  route_table_id            = aws_route_table.secondary_route_table.id
  destination_cidr_block    = var.primary_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary_vpc_peering.id
  depends_on                = [aws_vpc_peering_connection_accepter.secondary_vpc_peering_accepter]
}

##### SECURITY GROUPS AND NETWORK ACLS #####

resource "aws_security_group" "primary_sg" {
  name        = "primary-vpc-sg"
  description = "Security group for primary VPC"
  vpc_id      = aws_vpc.primary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  ingress {
    description = "Allow traffic from secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Primary-VPC-SG"
  }
}

resource "aws_security_group" "secondary_sg" {
  name        = "secondary-vpc-sg"
  description = "Security group for secondary VPC"
  vpc_id      = aws_vpc.secondary_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  ingress {
    description = "Allow traffic from primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Secondary-VPC-SG"
  }
}

resource "aws_network_acl" "primary_acl" {
  vpc_id     = aws_vpc.primary_vpc.id
  subnet_ids = [aws_subnet.primary_subnet.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "ACL1"
  }
}

resource "aws_network_acl" "secondary_acl" {
  vpc_id     = aws_vpc.secondary_vpc.id
  subnet_ids = [aws_subnet.secondary_subnet.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "ACL2"
  }
}

##### INSTANCES #####

resource "aws_instance" "primary_instance" {
  ami                    = data.aws_ami.primary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  user_data              = local.primary_user_data

  tags = {
    Name = "Primary-VPC-Instance"
  }
}

resource "aws_instance" "secondary_instance" {
  ami                    = data.aws_ami.secondary_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.secondary_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  user_data              = local.secondary_user_data

  tags = {
    Name = "Secondary-VPC-Instance"
  }
}



