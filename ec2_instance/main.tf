provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_instance" "jenQ" {
  ami           = "ami-020cba7c55df1f615" # Example AMI, replace with a valid one
  instance_type = "t2.micro"
  subnet_id     = data.aws_subnet.default.id
  associate_public_ip_address = true
  key_name = "jenQ1"

  tags = {
    Name = "jenQ-instance"  # 👈 This is what shows as the instance name
  }

}

## Output the public DNS name
output "jenQ_public_dns" {
  value = aws_instance.jenQ.public_dns
}