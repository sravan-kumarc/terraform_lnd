locals {
    project_name = "modelOne"
}

resource "aws_instance" "unixserver" {
  ami           = "ami-045443a70fafb8bbc"
  instance_type = "t3.nano"
  security_groups = ["default"]
  key_name = "mumbaiKP"

  tags = {
    Name = "${local.project_name}-UnixServer1"
  }
  
}
