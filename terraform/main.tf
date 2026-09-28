# S3 BUCKETS

resource "aws_s3_bucket" "bucket_a" {
  bucket = var.bucket_a_name
}

resource "aws_s3_bucket" "bucket_b" {
  bucket = var.bucket_b_name
}

# Versioning
resource "aws_s3_bucket_versioning" "bucket_a_versioning" {
  bucket = aws_s3_bucket.bucket_a.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "bucket_b_versioning" {
  bucket = aws_s3_bucket.bucket_b.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Public access block
resource "aws_s3_bucket_public_access_block" "bucket_a_block" {
  bucket = aws_s3_bucket.bucket_a.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "bucket_b_block" {
  bucket = aws_s3_bucket.bucket_b.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_a_encryption" {
  bucket = aws_s3_bucket.bucket_a.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_b_encryption" {
  bucket = aws_s3_bucket.bucket_b.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ASSESSMENT USERS

resource "aws_iam_user" "user_a" {
  name = var.user_a_name
}

resource "aws_iam_user_policy" "user_a_bucket_access" {
  name = "${var.user_a_name}-bucket-a-access"
  user = aws_iam_user.user_a.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucketA"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.bucket_a.arn
      },
      {
        Sid      = "ReadWriteBucketAObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.bucket_a.arn}/*"
      }
    ]
  })
}

resource "aws_iam_user" "user_b" {
  name = var.user_b_name
}

resource "aws_iam_user_policy" "user_b_bucket_access" {
  name = "${var.user_b_name}-bucket-b-read"
  user = aws_iam_user.user_b.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucketB"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.bucket_b.arn
      },
      {
        Sid      = "ReadBucketBObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.bucket_b.arn}/*"
      }
    ]
  })
}

# IAM ROLE FOR LAMBDA

resource "aws_iam_role" "lambda_role" {
  name = "image-processor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["s3:GetObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.bucket_a.arn}/*"
      },
      {
        Action   = ["s3:PutObject"]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.bucket_b.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logging" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# LAMBDA FUNCTION

resource "aws_lambda_function" "image_processor" {
  function_name = "s3-image-exif-processor"

  role    = aws_iam_role.lambda_role.arn
  handler = "app.lambda_handler"
  runtime = "python3.12"

  filename         = "${path.module}/../lambda/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/lambda.zip")

  timeout     = 10
  memory_size = 256
  publish     = true

  environment {
    variables = {
      DEST_BUCKET = aws_s3_bucket.bucket_b.bucket
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_policy,
    aws_iam_role_policy_attachment.lambda_logging
  ]
}

# S3 TRIGGER

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_a.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket_a.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.image_processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".jpg"
  }

  depends_on = [aws_lambda_permission.allow_s3]
}
