provider "aws" {
  region = "us-west-2" # Change to your desired AWS region
  
}

data "aws_vpc" "default_vpc" {
  default = true
  
}
data "aws_subnet" "default_subnet" {
  vpc_id = data.aws_vpc.default_vpc.id
  
}

resource "aws_instance" "hydrogen_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  count        = var.instance_count
  user_data = var.user_data
  associate_public_ip_address = true
  subnet_id = data.aws_subnet.default_subnet.id

  key_name = "jenQ"

  tags = {
    Name = "HydrogenInstance_TF"
  }
}