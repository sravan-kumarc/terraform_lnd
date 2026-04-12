#prod/vpc/terragrunt.hcl


include "root" {
  path   = find_in_parent_folders("root.hcl")
}

terraform {
  source = "${get_parent_terragrunt_dir()}/modules/vpc"
}

inputs = {
  cidr_block     = "192.168.0.0/16"
  aws_pub_subnet = "192.168.1.0/24"
  aws_pvt_subnet = "192.168.2.0/24"
  tag_name      = "prod-vpc"
  az             = "ap-south-2a"
}