output "bucket_name" {
    value = aws_s3_bucket.abc.bucket
}

output "bucket_arn" {
    value = aws_s3_bucket.abc.arn
}

output "bucket_tags" {
    value = aws_s3_bucket.abc.tags
}