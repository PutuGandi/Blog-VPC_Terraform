provider "aws" {
    region = "ap-southeast-1"
}

resource "aws_vpc" "gandi" {
    cidr_block       = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "Gandi-VPC"
    }
}

#Create Private Subnet
resource "aws_subnet" "private" {
    count                   = length(var.private_subnets)
    vpc_id                  = aws_vpc.gandi.id
    cidr_block              = var.private_subnets[count.index]
    availability_zone       = var.aws_availability_zones[count.index]
    map_public_ip_on_launch = false

    tags = {
        Name = var.private_names[count.index]
    }
}

#Create Public Subnet
resource "aws_subnet" "public" {
    count                   = length(var.public_subnets)
    vpc_id                  = aws_vpc.gandi.id
    cidr_block              = var.public_subnets[count.index]
    availability_zone       = var.aws_availability_zones[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = var.public_names[count.index]
    }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igwgandiVPC" {
    vpc_id = aws_vpc.gandi.id

    tags = {
      Name = "igw-GandiVPC"
    }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "rtpublic" {
    vpc_id = aws_vpc.gandi.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igwgandiVPC.id
    }

    tags = {
      Name = "rt-public"
    }
}   

resource "aws_route_table_association" "rtpublicassociation" {
    count          = length(var.public_subnets)
    subnet_id      = element(aws_subnet.public.*.id, count.index)
    route_table_id = aws_route_table.rtpublic.id
}

# Cretae NAT Gateway on AZ ap-shouteast-1a
resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "natgw-a" {
    allocation_id   = aws_eip.nat_gateway.id
    subnet_id       = element(aws_subnet.public.*.id, 0)

    tags = {
        "Name" = "NAT-GW-Public-A"
  }
}

# Cretae Route Table directing to NAT Gateway (ap-shouteas-1a)
resource "aws_route_table" "rtprivate-a" {
    vpc_id = aws_vpc.gandi.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_nat_gateway.natgw-a.id
    }

    tags = {
      Name = "rt-private-a"
    }
}   

resource "aws_route_table_association" "rtprivate-a-association" {
    subnet_id      = element(aws_subnet.private.*.id, 0)
    route_table_id = aws_route_table.rtprivate-a.id
}

# Create security group

resource "aws_security_group" "SGBastionHost" {
    vpc_id       = aws_vpc.gandi.id
    name         = "SGBastionHost"
    description  = "SGBastionHost"

    # allow ingress of port 22
    ingress {
      cidr_blocks = ["0.0.0.0/0"]
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    } 

    # allow egress of all ports
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }


    tags = {
        Name = "SGBastionHost"
        Description = "SGBastionHost"
    }
}

resource "aws_security_group" "SGPrivateA" {
    vpc_id       = aws_vpc.gandi.id
    name         = "SGPrivateA"
    description  = "SGPrivateA"

    # allow ingress of port 22
    ingress {
      security_groups = [aws_security_group.SGBastionHost.id]
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
    }

    # allow egress of all ports
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }


    tags = {
        Name = "SGPrivateA"
        Description = "SGPrivateA"
    }
}

# Create EC2
resource "aws_instance" "bastion" { 
	ami                     = "ami-03aad423811bbee56"
	instance_type           = "t2.micro"  
	vpc_security_group_ids  = [aws_security_group.SGBastionHost.id]
  key_name                = "Jumper-EC2"
	subnet_id               = element(aws_subnet.public.*.id,0)

  tags = {
        Name = "BastionHost"
    }
}

resource "aws_instance" "appA" { 
	ami                     = "ami-03aad423811bbee56"
	instance_type           = "t2.micro"  
	vpc_security_group_ids  = [aws_security_group.SGPrivateA.id]
  key_name                = "Jumper-EC2"
	subnet_id               = element(aws_subnet.private.*.id,0)

    tags = {
        Name = "App-Server-A"
    }
}
