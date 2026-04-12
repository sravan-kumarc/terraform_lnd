terraform{
backend "s3" {
  bucket = "terraform-state-locking-bucket26"
  key    = "statelock_lnd/terraform.tfstate"
  region = "ap-south-1"
  dynamodb_table = "terraform-state-locking-table26"
  
}
}