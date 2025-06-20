variable "instance_type" {
  description = "Declared TF variable for instance type."
  type        = string
  default     = "t2.micro"
  
}
variable "instance_count" {
  description = "Declared TF variable for instance count."
  type        = number
  default     = 1
  
}

variable "ami_id" {
  description = "Declared TF variable for AMI ID."
  type        = string
  default     = "ami-05f991c49d264708f" # Example AMI ID, replace with a valid one for your region
  
}

variable "user_data" {
  description = "Declared TF variable for user data script."
  type        = string
  default     = <<-EOF
    #!/bin/bash
    sudo apt update
    sudo apt install -y nginx
    systemctl start nginx
    systemctl enable nginx
    echo "Hello, World!" > /var/www/html/index.html
  EOF
  
}