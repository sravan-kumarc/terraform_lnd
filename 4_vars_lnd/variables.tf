variable "instance_type" {
  description = "The type of instance to use for the LND node."
  type        = string
  default     = "t3.micro"
}
variable "user_data" {
  description = "httpd vs nginx"
  type        = string
  default = "httpd"
}

variable "tags" {
    description = "A map of tags to assign to the resources."
    type        = map(string)
    default     = {
        Environment = "dev"
        Name        = "lnd-node_dev"
        Project     = "lnd-node_dev"
    }
  
}