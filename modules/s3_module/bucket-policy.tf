############################
# SOURCE BUCKET POLICY
############################
resource "aws_s3_bucket_policy" "source_policy_kms" {
  bucket = aws_s3_bucket.source.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Allow replication role to read with encryption conditions
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role_kms.arn
        }
        Action = [
          "s3:ListBucket",
          "s3:GetReplicationConfiguration",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectRetention",
          "s3:GetObjectLegalHold"
        ]
        Resource = [
          aws_s3_bucket.source.arn,
          "${aws_s3_bucket.source.arn}/*"
        ]
      },

      # Force SSE-KMS encryption
      {
        Sid = "DenyUnEncryptedUploads"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.source.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}

############################
# DESTINATION BUCKET POLICY
############################
resource "aws_s3_bucket_policy" "destination_policy_kms" {
  provider = aws.dest
  bucket   = aws_s3_bucket.destination.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Allow replication role to write
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.replication_role_kms.arn
        }
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}
