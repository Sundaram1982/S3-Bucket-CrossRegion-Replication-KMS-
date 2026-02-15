
data "aws_caller_identity" "current" {}

############################
# SOURCE REGION KMS KEY
############################
resource "aws_kms_key" "source_key" {
  description         = "KMS key for source S3 bucket"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Root account full control
      {
        Sid    = "RootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow S3 replication role to decrypt and generate data keys
      {
        Sid    = "AllowReplicationDecrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
      ,
      # Allow S3 service to use the key for replication on behalf of the account
      {
        Sid    = "AllowS3ServiceUse"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = [
              aws_s3_bucket.source.arn,
              "${aws_s3_bucket.source.arn}/*"
            ]
          }
        }
      }
    ]
  })
}


resource "aws_kms_alias" "source_alias" {
  name          = "alias/s3-source-key"
  target_key_id = aws_kms_key.source_key.key_id
}

############################
# DESTINATION REGION KMS KEY
############################
resource "aws_kms_key" "destination_key" {
  provider            = aws.dest
  description         = "KMS key for destination S3 bucket"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Root account full control
      {
        Sid    = "RootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow S3 replication role to encrypt, re-encrypt, and generate data keys
      {
        Sid    = "AllowReplicationEncrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
      ,
      # Allow S3 service to use the destination key for replication
      {
        Sid    = "AllowS3ServiceUseDest"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = [
              aws_s3_bucket.destination.arn,
              "${aws_s3_bucket.destination.arn}/*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "destination_alias" {
  provider      = aws.dest
  name          = "alias/s3-destination-key"
  target_key_id = aws_kms_key.destination_key.key_id
}

#################################
# ENABLE SSE-KMS ON SOURCE BUCKET
#################################
resource "aws_s3_bucket_server_side_encryption_configuration" "source_encryption" {
  bucket = aws_s3_bucket.source.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.source_key.arn
    }
  }
}

#####################################
# ENABLE SSE-KMS ON DESTINATION BUCKET
#####################################
resource "aws_s3_bucket_server_side_encryption_configuration" "destination_encryption" {
  provider = aws.dest
  bucket   = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.destination_key.arn
    }
  }
}
