resource "aws_instance" "smallservers" {
  ami           = "ami-0931307dcdc2a28c9"
  instance_type = var.instance_type

  user_data =( var.user_data == "httpd" ? <<-EOF
#!/bin/bash
dnf update -y
dnf install -y httpd
systemctl start httpd
systemctl enable httpd
EOF
  : <<-EOF
#!/bin/bash
dnf update -y
dnf install -y nginx
systemctl start nginx
systemctl enable nginx
EOF
  )
  user_data_replace_on_change = true
  tags = var.tags
}
