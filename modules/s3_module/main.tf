terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}
# -----------------------
# KMS Keys
# -----------------------
resource "aws_kms_key" "source_kms" {
  description         = "KMS key for source bucket"
  enable_key_rotation = true
}

resource "aws_kms_key" "dr_kms" {
  provider            = aws.dr
  description         = "KMS key for DR bucket"
  enable_key_rotation = true
}

# -----------------------
# S3 Buckets
# -----------------------
resource "aws_s3_bucket" "source" {
  bucket              = var.source_bucket_name
  object_lock_enabled = true
}

resource "aws_s3_bucket" "destination" {
  provider            = aws.dr
  bucket              = var.destination_bucket_name
  object_lock_enabled = true
}

# -----------------------
# Versioning
# -----------------------
resource "aws_s3_bucket_versioning" "source" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.dr
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------
# Encryption
# -----------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "source" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.source_kms.arn
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  provider = aws.dr
  bucket   = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.dr_kms.arn
    }
  }
}

# -----------------------
# Lifecycle rules
# -----------------------
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.source.id

  rule {
    id     = "tiered-storage"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# -----------------------
# Object Lock
# -----------------------
resource "aws_s3_bucket_object_lock_configuration" "lock" {
  bucket = aws_s3_bucket.source.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 30
    }
  }
}

# -----------------------
# Replication
# -----------------------
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role  = aws_iam_role.replication_role.arn

  rule {
    id     = "replication-rule"
    status = "Enabled"

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.dr_kms.arn
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_s3_bucket_versioning.destination
  ]
}

# -----------------------
# Enforce Encryption
# -----------------------
resource "aws_s3_bucket_policy" "enforce_encryption" {
  bucket = aws_s3_bucket.source.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyUnEncryptedUploads"
      Effect = "Deny"
      Principal = "*"
      Action = "s3:PutObject"
      Resource = "${aws_s3_bucket.source.arn}/*"
      Condition = {
        StringNotEquals = {
          "s3:x-amz-server-side-encryption" = "aws:kms"
        }
      }
    }]
  })
}

# -----------------------
# SNS + CloudWatch Alarm
# -----------------------
resource "aws_sns_topic" "replication_alert" {
  name = "${var.project_name}-replication-alert"
}

resource "aws_cloudwatch_metric_alarm" "replication_alarm" {
  alarm_name          = "${var.project_name}-replication-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OperationsFailedReplication"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  alarm_actions = [aws_sns_topic.replication_alert.arn]

  dimensions = {
    BucketName = aws_s3_bucket.source.bucket
  }
}
