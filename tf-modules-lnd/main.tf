module "webserver" {
  source = "./module-1/webserver"

  name          = "web-server"
  ami_id        = "ami-03cc02f29b2a8bc8f"
  instance_type = "t3.micro"
  key_name     = "5607-mumbaikp"

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from Terraform" > /var/www/html/index.html
              EOF
}
