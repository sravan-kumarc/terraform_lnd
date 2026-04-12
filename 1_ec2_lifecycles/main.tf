# EC2 TF- TEMPLATE
provider "aws" {
  region = var.region
}
/**
resource "null_resource" "ec2_trigger" {
  triggers = {
    instance_type = "t3.small"
    sg            = "sg-0e1d5f61b81fb225a"
  }
}**/

resource "aws_instance" "dev_instance" {
  ami           = "ami-048f4445314bcaa09"
  instance_type = "t3.micro"
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
    Name = "DevInstance-post-amend"
  }

  /**lifecycle {
    
    /**prevent_destroy = true **/ //P1
    /**create_before_destroy = true **/ //P2
    /**
    ignore_changes = [ 
      tags
     ]
  } 
  create_before_destroy = true
  replace_triggered_by = [ 
    null_resource.ec2_trigger
  ] **/


  lifecycle {
    postcondition {
      condition = self.subnet_id == "subnet-01be6d314a76861f2"
      error_message = "something not GOOD"
    }
  }


  }

output "devinstanceop" {
    value = {
      public_ip = aws_instance.dev_instance[0].public_ip
      ami       = aws_instance.dev_instance[0].ami
      instance_type = aws_instance.dev_instance[0].instance_type
    }
}
