data "aws_vpc" "inbuiltvpc" {
  filter {
    name   = "tag:Name"
    values = ["lnd_default"]
  }
}
data "aws_availability_zones" "availablezonesare" {}

data "aws_subnet" "pickone" {
    filter {
        name = "availability-zone"
        values = [data.aws_availability_zones.availablezonesare.names[0]]
    }
    filter {
    name   = "vpc-id"
    values = [data.aws_vpc.inbuiltvpc.id]
    }
}

data "aws_security_group" "existingsgs" {
  filter {
    name   = "tag:Name"
    values = ["customized4internal"]
  }
  vpc_id = data.aws_vpc.inbuiltvpc.id
}

data "aws_key_pair" "lndkeypair" {
  key_name = "mumbaiKP"
}

resource "aws_instance" "devspacelaunch" {
  ami           = "ami-045443a70fafb8bbc"
  instance_type = "t3.micro"
  subnet_id     = data.aws_subnet.pickone.id
  key_name      = data.aws_key_pair.lndkeypair.key_name
  vpc_security_group_ids = [ data.aws_security_group.existingsgs.id ]

  tags = {
    Name = "box1-ind-internal"
  }
  
}