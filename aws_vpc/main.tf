provider "aws" {
  region = "us-west-1" 
}

resource "aws_vpc" "zinc-vpc" {
  cidr_block = "10.0.0.0/24"
    tags = {
        Name = "zinc-vpc"
    }
}

resource "aws_subnet" "zinc-pb-subnet1" {
  vpc_id            = aws_vpc.zinc-vpc.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "us-west-1a"

  tags = {
    Name = "zinc-pb-subnet"
  }
}

resource "aws_subnet" "zinc-pb-subnet2" {
  vpc_id            = aws_vpc.zinc-vpc.id
  cidr_block        = "10.0.0.128/25"
  availability_zone = "us-west-1a"

  tags = {
    Name = "zinc-pb-subnet2"
  }
}

resource "aws_internet_gateway" "zinc-igw" {
  vpc_id = aws_vpc.zinc-vpc.id

  tags = {
    Name = "zinc-igw"
  }
}
resource "aws_route_table" "zinc-rt" {
  vpc_id = aws_vpc.zinc-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.zinc-igw.id
  }
}
resource "aws_route_table_association" "zinc-rt-assoc1" {
  subnet_id      = aws_subnet.zinc-pb-subnet1.id
  route_table_id = aws_route_table.zinc-rt.id
}
resource "aws_route_table_association" "zinc-rt-assoc2" {
  subnet_id      = aws_subnet.zinc-pb-subnet2.id
  route_table_id = aws_route_table.zinc-rt.id
}
resource "aws_security_group" "zinc-sg" {
  name        = "zinc-sg"
  description = "Security group for Zinc VPC"
  vpc_id      = aws_vpc.zinc-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere
    }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "zinc-sg"
    }
}

output "all_resouces_details" {
  value = {
    vpc_id              = aws_vpc.zinc-vpc.id
    subnet1_id          = aws_subnet.zinc-pb-subnet1.id
    subnet2_id          = aws_subnet.zinc-pb-subnet2.id
    internet_gateway_id = aws_internet_gateway.zinc-igw.id
    route_table_id      = aws_route_table.zinc-rt.id
    security_group_id   = aws_security_group.zinc-sg.id
  }  
}