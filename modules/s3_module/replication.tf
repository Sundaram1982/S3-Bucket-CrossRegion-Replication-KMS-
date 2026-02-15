resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role  = aws_iam_role.replication_role.arn

  rule {
    id       = "replication-rule"
    status   = "Enabled"
    priority = 1

    filter {
      prefix = ""
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket           = aws_s3_bucket.destination.arn
      storage_class    = "STANDARD"
      
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination_key.arn
      }
      
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
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
