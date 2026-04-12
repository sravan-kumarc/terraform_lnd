resource "aws_vpc" "mainvpc" {
    cidr_block = var.cidr_block

    tags = {
        Name = var.tag_name
    }
  
}

resource "aws_subnet" "pubsn1" {
    vpc_id = aws_vpc.mainvpc.id
    cidr_block = var.aws_pub_subnet
    availability_zone = var.az
    map_public_ip_on_launch = true
    tags = {
        Name = "${var.tag_name}-pubsn1"
    }
}

resource "aws_subnet" "pvtsn1" {
    vpc_id = aws_vpc.mainvpc.id
    cidr_block = var.aws_pvt_subnet
    availability_zone = var.az
    tags = {
      Name = "${var.tag_name}-pvtsn1"
    }
}

resource "aws_internet_gateway" "myvpcigw" {
    vpc_id = aws_vpc.mainvpc.id
    tags = {
      Name = "${var.tag_name}-igw"
    }
}

resource "aws_route_table" "rt4mainvpc_pub" {
    vpc_id = aws_vpc.mainvpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myvpcigw.id
    }
    tags = {
       Name = "${var.tag_name}-rt4mainvpc_pub"
    }
  
}

resource "aws_route_table_association" "rt4mainvpc_assoc" {
    subnet_id = aws_subnet.pubsn1.id
    route_table_id = aws_route_table.rt4mainvpc_pub.id

}

resource "aws_route_table" "rt4mainvpc_pvt" {
    vpc_id = aws_vpc.mainvpc.id
    tags = {
        Name = "${var.tag_name}-rt4mainvpc_pvt"
    }
}

resource "aws_route_table_association" "rt4mainvpc_pvt_assoc" {
    subnet_id = aws_subnet.pvtsn1.id
    route_table_id = aws_route_table.rt4mainvpc_pvt.id



}