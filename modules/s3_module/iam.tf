resource "aws_iam_role" "replication_role_kms" {
  name = "s3-replication-role-kms"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "replication_policy_kms" {
  name = "s3-replication-policy-kms"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Read from source bucket
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = [
          aws_s3_bucket.source.arn,
          "${aws_s3_bucket.source.arn}/*"
        ]
      },

      # Write to destination bucket
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:ObjectOwnerOverrideToBucketOwner"
        ]
        Resource = "${aws_s3_bucket.destination.arn}/*"
      },

      # KMS source key
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.source_key.arn
      },

      # KMS destination key
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.destination_key.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.replication_role_kms.name
  policy_arn = aws_iam_policy.replication_policy_kms.arn
}
