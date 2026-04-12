resource "aws_instance" "webserver" {
  ami           = "ami-045443a70fafb8bbc" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  key_name = aws_key_pair.safekey.key_name
  user_data = <<-EOF
              #!/bin/bash
              sudo dnf install -y httpd
              sudo systemctl enable httpd
              sudo systemctl start httpd
              echo 'Hello from NullResource- $(hostname -f)' > /var/www/html/index.html
            EOF
  tags = {
    Name = "TerraformLND-NullResource"
    Environment = "NullResource"
  }
  
}
resource "aws_key_pair" "safekey" {
  key_name   = "safe-key"
  public_key = file("/home/sravan/.ssh/id_ed25519.pub")
  
}

output "getipadd" {
    value = aws_instance.webserver.public_ip
}

resource "null_resource" "runon" {
    depends_on = [ aws_instance.webserver ]
    triggers = {
      file_hash = filemd5("index.html")
    }
    connection {
      type = "ssh"
      user = "ec2-user"
      private_key = file("/home/sravan/.ssh/id_ed25519")
      host = aws_instance.webserver.public_ip
    }
    provisioner "file" {
      source = "index.html"
      destination = "/tmp/index.html"
    }
    provisioner "remote-exec" {
      inline = [
        "mkdir -p /var/www/html",
        "sudo mv /tmp/index.html /var/www/html/index.html",
        "sudo systemctl reload httpd || sudo systemctl restart httpd"
      ]
}
}




