locals {
   user_data_httpd =<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "Hello from ${terraform.workspace}- $(hostname -f)" > /var/www/html/index.html
              EOF

  user_data_nginx =<<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo amazon-linux-extras install nginx1.12 -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "Hello from ${terraform.workspace}- $(hostname -f)" > /usr/share/nginx/html/index.html
              EOF
}  

resource "aws_instance" "env-instance" {
  ami           = "ami-045443a70fafb8bbc" # Amazon Linux 2 AMI
  instance_type = var.instance_type
  user_data_replace_on_change = true
  user_data = var.user_data == "httpd" ? local.user_data_httpd : local.user_data_nginx #(...?...:...)
  key_name = "mumbaiKP"

  tags = {
    Name = "TerraformLND-${terraform.workspace}"
    Environment = terraform.workspace
  }
  
}