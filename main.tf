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
  availability_zone = "eu-west-2a"

  tags = {
    Name = "capstone-private-subnet-01"
    created = "Lington"
  }
}

resource "aws_subnet" "capstone-private-subnet-02" {
  vpc_id     = aws_vpc.capstone-vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "eu-west-2a"

  tags = {
    Name = "capstone-private-subnet-02"
    created = "Lington"
  }
}

resource "aws_subnet" "capstone-private-subnet-03" {
  vpc_id            = aws_vpc.capstone-vpc.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "eu-west-2c"

  tags = {
    Name    = "capstone-private-subnet-03"
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

# Create IAM Role and give full s3 Access
resource "aws_iam_role" "s3_full_access_role" {
  name = "s3_full_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.s3_full_access_role.name
}

# Create DB subnet group
# it is this subnet group for the DB

resource "aws_db_subnet_group" "capstone-db-group-subnet" {
  name       = "capstone-db-group-subnet"
  subnet_ids = [aws_subnet.capstone-private-subnet-01.id, aws_subnet.capstone-private-subnet-02.id, aws_subnet.capstone-private-subnet-03.id]
  #availability_zone = ["eu-west-2a", "eu-west-2b"]


  tags = {
    Name = "capstone-db-group-subnet"
  }
}

# Create Database ( this is cheaper and for instance, only requires two private subnet)
resource "aws_db_instance" "capstone-database" {
  allocated_storage      = 10
  identifier             = "capstone-db"
  multi_az               = true
  db_name                = "lingtondb"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  username               = "lingtondatabase"
  password               = "test1234"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.capstone-db-group-subnet.id
  vpc_security_group_ids = [aws_security_group.capstone-Back-end-SG.id]

}

#Create S3 Buckets onem for media and one for code
#Create capstone S3 Media Bucket   // this is where we can serve our media from like the cloudfront
resource "aws_s3_bucket" "capstone-media1-bucket" {
  bucket        = "capstone-media1-bucket"
  force_destroy = true

  tags = {
    Name        = "capstone-media1-bucket"
    Environment = "Devops"
  }
}

resource "aws_s3_bucket_acl" "capstone-media1-bucket-acl" {
  bucket = aws_s3_bucket.capstone-media1-bucket.id
  acl    = "public-read"
}

#Attach a policy to Media Bucket   //this policy is to make it public
resource "aws_s3_bucket_policy" "capstone-media1-bucket-policy" {
  bucket = aws_s3_bucket.capstone-media1-bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Action" : [
          "s3:GetObject"
        ],
        "Effect" : "Allow",
        "Resource" : "arn:aws:s3:::capstone-media1-bucket/*",
        "Principal" = {
          AWS = "*"
        }
      }
    ]
    }
  )
}

#Create capstone S3 Media Bucket 
#Create capstone S3 Code Bucket
resource "aws_s3_bucket" "capstone-code1-bucket" {
  bucket        = "capstone-code1-bucket"
  force_destroy = true

  tags = {
    Name        = "capstone-code1-bucket"
    Environment = "Devops"
  }
}

resource "aws_s3_bucket_acl" "capstone-code1-bucket-acl" {
  bucket = aws_s3_bucket.capstone-code1-bucket.id
  acl    = "private"   # this code bucket is not publicly access
}