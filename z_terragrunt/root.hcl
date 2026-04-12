#/z_terragrunt/root.hcl

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents = <<EOF
provider "aws" {
  region              = "ap-south-2"
}
EOF
}



remote_state {
  backend = "s3"
  config = {
    bucket = "mybucket-2manage-terragrunt-backend"
    key    = "${path_relative_to_include()}/terragrunt.tfstate"
    region = "ap-south-2"
  }
  generate ={
    path = "backend.tf"
    if_exists = "overwrite"
  }
}