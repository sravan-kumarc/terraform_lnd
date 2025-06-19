provider "aws" {
  region = "us-west-2" # Change to your desired region
  
}

resource "aws_s3_bucket" "hellium_bucket" {
  bucket = "helium-bucket-01" # Change to a unique bucket name
    tags = {
        Name        = "Helium Bucket"
        Environment = "Development"
    }

}
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.hellium_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.hellium_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

terraform {
  backend "s3" {
    bucket = "helium-bucket-01" # Use the actual bucket name, not a reference
    key    = "terraform.tfstate"
    region = "us-west-2" # Change to your desired region
  }
}