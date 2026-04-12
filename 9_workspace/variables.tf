variable "instance_type" {
  description = "The type of instance to use for the EC2 instance."
  type        = string
  default     = "t3.micro"
  
}

variable "user_data" {
    type = string
    description = "User data script to initialize the EC2 instance default - httpd."
    default = "httpd"
  
}