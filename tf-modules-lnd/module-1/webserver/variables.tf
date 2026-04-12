
variable "instance_type" {
    type = string
    description = "EC2 instance type"
}

variable "ami_id" {
    type = string
    description = "EC2 AMI ID"  
}

variable "key_name" {
    type = string
    description = "EC2 Key name"
  
}

variable "name"{
    type = string
}

variable "user_data" {

    type = string
    description = "user_data"
}
