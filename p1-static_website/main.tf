# 1. S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "staticwebsitedeliverybucket-unique-skc"
}

# 2. Disable Block Public Access
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. Bucket Policy (Public Read)
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.bucket.id

  depends_on = [aws_s3_bucket_public_access_block.public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.bucket.arn}/*"]
      }
    ]
  })
}

# 4. Website Configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# 5. Upload ALL Files from dist/
resource "aws_s3_object" "files" {
  for_each = fileset("${path.module}/dist", "**")

  bucket = aws_s3_bucket.bucket.id
  key    = each.value
  source = "${path.module}/dist/${each.value}"

  etag = filemd5("${path.module}/dist/${each.value}")

#####content_type = lookup({...}, extension, "application/octet-stream")####
  content_type = lookup({
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "jpg"  = "image/jpeg"
    "svg"  = "image/svg+xml"
    "ico"  = "image/x-icon"
    "txt"  = "text/plain"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")
}

# 6. Output URL
output "website_url" {
  value = aws_s3_bucket_website_configuration.website.website_endpoint
}