resource "aws_vpc" "main_vpc" {
  cidr_block = "192.168.0.0/16"

    tags = {
        Name = "MainVPC_TF"
    }
}
resource "aws_subnet" "public_subnet1" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = "192.168.0.0/18"
    availability_zone = "ap-south-1a"
    map_public_ip_on_launch = true

    tags = {
      env = "dev"
    }
}
resource "aws_subnet" "public_subnet2" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = "192.168.64.0/18"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true

    tags = {
      env = "dev"
    }
}
resource "aws_subnet" "public_subnet3" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = "192.168.128.0/19"
    availability_zone = "ap-south-1c"
    map_public_ip_on_launch = true

    tags = {
      env = "dev"
    }
}
resource "aws_subnet" "private_subnet1" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = "192.168.160.0/19"
    availability_zone = "ap-south-1a"

    tags = {
      env = "dev"
    } 
}
resource "aws_subnet" "private_subnet2" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = "192.168.192.0/19"
    availability_zone = "ap-south-1b"

    tags = {
      env = "dev"
    } 
}
resource "aws_subnet" "private_subnet3" {
    vpc_id     = aws_vpc.main_vpc.id
    cidr_block = "192.168.224.0/19"
    availability_zone = "ap-south-1c"

    tags = {
      env = "dev"
    } 
}
resource "aws_internet_gateway" "igw_mainVPC" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
      Name = "MainVPC-IGW"
    }
}
resource "aws_route_table" "mainvpcrt" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_mainVPC.id
    }

    tags = {
      Name = "MainVPCRT"
    }
}
resource "aws_route_table_association" "public_subnet_association" {
    for_each = {
      pubsubnet1 = aws_subnet.public_subnet1.id
      pubsubnet2 = aws_subnet.public_subnet2.id
      pubsubnet3 = aws_subnet.public_subnet3.id
    }
    subnet_id = each.value
    route_table_id = aws_route_table.mainvpcrt.id
}
resource "aws_security_group" "mainvpcsg" {
    name        = "MainVPC-SG"
    description = "Security group for Main VPC"
    vpc_id      = aws_vpc.main_vpc.id

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
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
}
resource "aws_instance" "EC2_CustomVPC" {
    ami = "ami-0931307dcdc2a28c9"
    instance_type = "t3.micro"
    key_name = "mumbaiKP"
    associate_public_ip_address = true
    subnet_id = aws_subnet.public_subnet1.id
    vpc_security_group_ids = [aws_security_group.mainvpcsg.id]
    user_data = <<-EOF
                #!/bin/bash
                sudo dnf install httpd -y
                sudo systemctl start httpd
                sudo systemctl enable httpd
                echo "Hello from Main VPC EC2 Instance created with Terraform!" > /var/www/html/index.html
            EOF
}
output "vpcs" {
    value = {
        vpc_id = aws_vpc.main_vpc.id
        cidr_block = aws_vpc.main_vpc.cidr_block

        public_subnet_id1 = aws_subnet.public_subnet1.id
        public_subnet_id2 = aws_subnet.public_subnet2.id
        public_subnet_id3 = aws_subnet.public_subnet3.id

        private_subnet_id1 = aws_subnet.private_subnet1.id
        private_subnet_id2 = aws_subnet.private_subnet2.id
        private_subnet_id3 = aws_subnet.private_subnet3.id

        igw_id = aws_internet_gateway.igw_mainVPC.id

        route_table_id = aws_route_table.mainvpcrt.id
        security_group_id = aws_security_group.mainvpcsg.id

        public_ip =aws_instance.EC2_CustomVPC.public_ip
    }
}