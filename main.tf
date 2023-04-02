#   I AM REPLICATING MY CAPSTONE PROJECT HERE
# REQUIREMENTS 
# 1. Provisioning Infrastructure
# a. VPC, Subnets (2 public & private in 2 AZ), IGW, NG, Route tables, Security Groups.

# Create custom vpc

resource "aws_vpc" "capstone-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "capstone-vpc"
    created = "Lington"
  }
}

# Create 2 public subnet
# it is this subnet that will enable people to publicly access our infrastructure

resource "aws_subnet" "capstone-public-subnet-01" {
  vpc_id     = aws_vpc.capstone-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "capstone-public-subnet-01"
    created = "Lington"
  }
}

resource "aws_subnet" "capstone-public-subnet-02" {
  vpc_id     = aws_vpc.capstone-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "capstone-public-subnet-02"
    created = "Lington"
  }
}

# Create 2 private subnet
# this subnet is not publicly access because we are using it for our RDS

resource "aws_subnet" "capstone-private-subnet-01" {
  vpc_id     = aws_vpc.capstone-vpc.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "capstone-private-subnet-01"
    created = "Lington"
  }
}

resource "aws_subnet" "capstone-private-subnet-02" {
  vpc_id     = aws_vpc.capstone-vpc.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "capstone-private-subnet-02"
    created = "Lington"
  }
}

# Create internet Gate way

resource "aws_internet_gateway" "capstone-igw" {
  vpc_id = aws_vpc.capstone-vpc.id

  tags = {
    Name = "capstone-igw"
    created = "Lington"
  }
}

# Create public route table
resource "aws_route_table" "capstone-public-RT" {
  vpc_id = aws_vpc.capstone-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone-igw.id
  }

  tags = {
    Name = "capstone-public-RT"
  }
}

# Create public route table association for subnet 01 nad 02

resource "aws_route_table_association" "capstone-RT-01-Association" {
  subnet_id      = aws_subnet.capstone-public-subnet-01.id
  #subnet_id      = aws_subnet.capstone-public-subnet-02.id
  route_table_id = aws_route_table.capstone-public-RT.id
}

resource "aws_route_table_association" "capstone-RT-02-Association" {
  #subnet_id      = aws_subnet.capstone-public-subnet-01.id
  subnet_id      = aws_subnet.capstone-public-subnet-02.id
  route_table_id = aws_route_table.capstone-public-RT.id
}


# Create NAT Gate way # NOTE ALWAYS CREATE THE ELLASTIC IP(EIP) first before you you create the nat gate way
# also it is always a dependency of IGW

resource "aws_eip" "elastic-ip" {

    #EIP may require IGW to exist prior to association
    # use depends on to an explicit dependency on IGW
    
    depends_on = [aws_internet_gateway.capstone-igw]
  
}
# Create NAT Gate way

resource "aws_nat_gateway" "capstone-NAT-gw" {
 # connectivity_type = "private"  # public is the default so we can completely take this line out
  allocation_id = aws_eip.elastic-ip.id
  subnet_id = aws_subnet.capstone-public-subnet-02.id # we always use public subnet to connect our front end to back but peopple can access it puplicly over the internet

tags = {
    Name = "capstone-NAT-gw"
  }

}

# Create private route table
resource "aws_route_table" "capstone-private-RT" {
  vpc_id = aws_vpc.capstone-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.capstone-NAT-gw.id
  }

  tags = {
    Name = "capstone-private-RT"
  }
}

# Create private route table association for subnet 01 nad 02

resource "aws_route_table_association" "capstone-RT-001-Association" {
  subnet_id      = aws_subnet.capstone-private-subnet-01.id
  route_table_id = aws_route_table.capstone-private-RT.id
}

resource "aws_route_table_association" "capstone-RT-002-Association" {
  subnet_id      = aws_subnet.capstone-private-subnet-02.id
  route_table_id = aws_route_table.capstone-private-RT.id
}

# Create a Security group (FRONT END)

resource "aws_security_group" "capstone-Front-end-SG" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.capstone-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "capstone-Front-end-SG"
  }
}

# Create a Security group (BACK END)

resource "aws_security_group" "capstone-Back-end-SG" {
  name        = "allow_tlss"  # note both security group cant have the same name

  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.capstone-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.capstone-Front-end-SG.id]
    
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 3306
    to_port          = 3306
    protocol         = "tcp"
    security_groups  = [aws_security_group.capstone-Front-end-SG.id]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "capstone-Back-end-SG"
  }
}

