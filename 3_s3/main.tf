resource "aws_s3_bucket" "tf_bucket" {
  bucket = "a-bucket-created-by-using-terraform"

}

resource "aws_s3_bucket_public_access_block" "blockpublicaccess" {
    bucket = aws_s3_bucket.tf_bucket.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true

}

resource "aws_s3_bucket_versioning" "versioning" {
    bucket = aws_s3_bucket.tf_bucket.id

    versioning_configuration {
        status = "Enabled"
    }
  
}
resource "aws_s3_object" "object1" {
    bucket = aws_s3_bucket.tf_bucket.id
    key    = "file1.txt"
    source = "./file1.txt"
}

