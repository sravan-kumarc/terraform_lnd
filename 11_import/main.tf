resource "aws_instance" "imported_instance" {
  ami                         = "ami-045443a70fafb8bbc"
  instance_type               = "t3.small"
  subnet_id                   = "subnet-0e63891417c5889e3"
  vpc_security_group_ids      = ["sg-09c20659603556222"]
  key_name                    = "mumbaiKP"
  associate_public_ip_address = true

  tags = {
    Name = "unixServer_modifyingaftertfimport"
  }

  root_block_device {
    volume_size = 8
    volume_type = "gp3"
  }
}