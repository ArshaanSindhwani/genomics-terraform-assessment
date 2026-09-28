variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "bucket_a_name" {
  description = "Source S3 bucket"
  type        = string
}

variable "bucket_b_name" {
  description = "Destination S3 bucket"
  type        = string
}

variable "user_a_name" {
  description = "IAM username for the assessment user with read/write access to Bucket A"
  type        = string
  default     = "user-a"
}

variable "user_b_name" {
  description = "IAM username for the assessment user with read access to Bucket B"
  type        = string
  default     = "user-b"
}
