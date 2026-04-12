# EC2 TF- TEMPLATE
provider "aws" {
  region = var.region
}

resource "aws_instance" "dev_instance" {
  ami           = "ami-048f4445314bcaa09"
  instance_type = "t3.nano"
  count        = 1
  key_name      = "mumbaiKP"
  subnet_id =  "subnet-01be6d314a76861f2"
  vpc_security_group_ids = ["sg-0ac78194f666aeff4"]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              set -e
              sudo dnf install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              echo "Hello, World!" > /var/www/html/index.html
              EOF

  tags = {
    Name = "DevInstance"
  }
  
  
  lifecycle {
    
    /**prevent_destroy = true **/ //P1
    
    create_before_destroy = true
    
    /**ignore_changes = [ 
      tags
     ] **/
  } 
/**
  lifecycle {
    precondition {
      condition = self.subnet_id == "subnet-04c08cc1eef57d330"
      error_message = "ALL SEEMS GOOD"
    }
  }
**/

}

output "devinstanceop" {
    value = {
      public_ip = aws_instance.dev_instance[0].public_ip
      ami       = aws_instance.dev_instance[0].ami
      instance_type = aws_instance.dev_instance[0].instance_type
    }
}
