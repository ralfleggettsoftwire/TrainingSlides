resource "aws_s3_bucket" "s3_bucket" {
  bucket = "website"
}

resource "aws_s3_bucket_website_configuration" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

# Seems like it's not necessary if specifying on each S3 object:
# resource "aws_s3_bucket_acl" "s3_bucket" {
#   bucket = aws_s3_bucket.s3_bucket.id
#   acl    = "public-read"
# }

resource "aws_s3_object" "object_website" {
  depends_on   = [aws_s3_bucket.s3_bucket]
  for_each     = fileset("${path.root}", "website/*.html")
  bucket       = aws_s3_bucket.s3_bucket.bucket
  key          = basename(each.value)
  source       = each.value
  etag         = filemd5("${each.value}")
  content_type = "text/html"
  acl          = "public-read"
}

# resource "aws_s3_object" "object_assets" {
#   depends_on = [aws_s3_bucket.s3_bucket]
#   for_each   = fileset(path.module, "assets/*")
#   bucket     = var.bucket_name
#   key        = each.value
#   source     = "${each.value}"
#   etag       = filemd5("${each.value}")
#   acl        = "public-read"
# }

resource "aws_s3_bucket_policy" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.s3_bucket.arn,
          "${aws_s3_bucket.s3_bucket.arn}/*",
        ]
      },
    ]
  })
}