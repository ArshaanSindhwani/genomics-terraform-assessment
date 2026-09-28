output "bucket_a" {
  value = aws_s3_bucket.bucket_a.bucket
}

output "bucket_b" {
  value = aws_s3_bucket.bucket_b.bucket
}

output "user_a_arn" {
  description = "IAM user with read/write access to Bucket A"
  value       = aws_iam_user.user_a.arn
}

output "user_b_arn" {
  description = "IAM user with read access to Bucket B"
  value       = aws_iam_user.user_b.arn
}
