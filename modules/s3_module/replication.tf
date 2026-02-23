resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication_role_kms.arn

  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_s3_bucket_versioning.destination,
    aws_s3_bucket_server_side_encryption_configuration.source_encryption,
    aws_s3_bucket_server_side_encryption_configuration.destination_encryption
  ]

  rule {
    id     = "${var.source_region}-${var.destination_region}-s3-replication-rule"
    status = "Enabled"
    filter {}

    # Only replicate KMS-encrypted objects
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"

      # Re-encrypt with destination KMS key
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination_key.arn
      }

      # Enable metrics for replication monitoring
      metrics {
        status = "Enabled"

        event_threshold {
          minutes = 15
        }
      }

      # Enable replication time control
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }

    # Replicate deletion markers
    delete_marker_replication {
      status = "Enabled"
    }
  }
}
