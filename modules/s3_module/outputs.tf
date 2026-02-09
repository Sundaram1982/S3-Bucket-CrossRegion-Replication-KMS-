output "source_bucket" {
  value = aws_s3_bucket.source.bucket
}

output "destination_bucket" {
  value = aws_s3_bucket.destination.bucket
}
