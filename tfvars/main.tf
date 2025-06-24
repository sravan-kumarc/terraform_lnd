provider "aws" {
  region = "us-west-2"
  
}
resource "aws_instance" "hydrogen" {
    ami = var.ec2_instance_ami
    instance_type = var.ec2_instance_type
    subnet_id = "subnet-083b5bf951b0187cd" # 👈 Replace with your actual subnet ID

    tags = {
      Name = "HydrogenInstance"
    } 
}
