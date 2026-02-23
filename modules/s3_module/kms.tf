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
      # Root account full access
      {
        Sid    = "RootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow replication role to decrypt with conditions
      {
        Sid    = "AllowReplicationRoleDecrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role_kms.arn
        }
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.source_region}.amazonaws.com"
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

      # Root account full access
      {
        Sid    = "RootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },

      # Allow replication role to encrypt with conditions
      {
        Sid    = "AllowReplicationRoleEncrypt"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role_kms.arn
        }
        Action = [
          "kms:Encrypt"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.destination_region}.amazonaws.com"
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

#################################
# ENABLE SSE-KMS ON DEST BUCKET
#################################
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
