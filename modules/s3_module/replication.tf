resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role  = aws_iam_role.replication_role_kms.arn

  rule {
    id     = "replication-rule"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # REQUIRED when using KMS encryption_configuration
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination_key.arn
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_s3_bucket_versioning.destination
  ]
}
