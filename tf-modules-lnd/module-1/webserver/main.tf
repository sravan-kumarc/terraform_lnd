provider "aws" {
  region = "ap-south-2"
}

data "aws_vpc" "defvpc" {
  filter {
    name   = "tag:Name"
    values = ["project_ecs-vpc"]
  }
}

data "aws_subnets" "defvpc_sn" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.defvpc.id]
    }
  
}
resource "aws_instance" "unix_webserver" {
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.key_name
    subnet_id = data.aws_subnets.defvpc_sn.ids[0]
    associate_public_ip_address = true
    user_data = var.user_data
    vpc_security_group_ids = [ aws_security_group.mybuiltinsg.id ]

    tags = {
        Name = "${var.name}-unix_webserver"
    }  
}

resource "aws_security_group" "mybuiltinsg" {
    name = "${var.name}-sg"
    description = "Allow TLS inbound traffic"
    vpc_id = data.aws_vpc.defvpc.id

    ingress {
        description = "TLS from VPC"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "TLS from VPC"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "${var.name}-sg"
    }
  
}

