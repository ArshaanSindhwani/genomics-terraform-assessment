variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-2"
}

variable "bucket_a_name" {
  description = "Source S3 bucket"
}

variable "bucket_b_name" {
  description = "Destination S3 bucket"
}