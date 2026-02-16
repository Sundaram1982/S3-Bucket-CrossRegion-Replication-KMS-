# S3 Replication with KMS Encryption - Resource Details

This document contains the resource names and ARNs for the S3 cross-region replication infrastructure with KMS encryption support.

## S3 Buckets

| Resource | Name | Region |
|----------|------|--------|
| Source Bucket | `kms-demo-source-bucket-primary-11111` | us-east-1 |
| Destination Bucket | `kms-demo-destination-bucket-secondary-22222` | us-west-2 |

## IAM Role

| Property | Value |
|----------|-------|
| Role Name | `s3-replication-role-kms` |
| Role ARN | `arn:aws:iam::692681389816:role/s3-replication-role-kms` |
| Trust Policy Principal | `s3.amazonaws.com` (S3 service) |
| Account ID | `692681389816` |

## IAM Policy

| Property | Value |
|----------|-------|
| Policy Name | `s3-replication-policy-kms` |
| Policy ARN | `arn:aws:iam::692681389816:policy/s3-replication-policy-kms` |
| Attached To | `s3-replication-role-kms` |

**Policy Permissions:**
- **S3 Source Bucket Actions**: `GetObjectVersion`, `GetObjectVersionAcl`, `GetObjectVersionTagging`, `GetBucketVersioning`, `ListBucket`, `GetReplicationConfiguration`
- **S3 Destination Bucket Actions**: `ReplicateObject`, `ReplicateDelete`, `ReplicateTags`, `ObjectOwnerOverrideToBucketOwner`
- **KMS Source Key Actions**: `Decrypt`, `ReEncryptFrom`, `GenerateDataKey*`, `DescribeKey`
- **KMS Destination Key Actions**: `Encrypt`, `Decrypt`, `ReEncrypt*`, `GenerateDataKey*`, `DescribeKey`

## KMS Keys

### Source Key (us-east-1)

| Property | Value |
|----------|-------|
| Key Alias | `alias/s3-source-key` |
| Region | us-east-1 |
| Description | KMS key for source S3 bucket |
| Key Rotation | Enabled |

**Key Policy Statements:**
- Root account full access (`kms:*`)
- Replication role: `Decrypt`, `ReEncryptFrom`, `GenerateDataKey*`, `DescribeKey`
- S3 Service Principal: `Decrypt`, `GenerateDataKey*`, `DescribeKey` (with conditions for source bucket)

### Destination Key (us-west-2)

| Property | Value |
|----------|-------|
| Key Alias | `alias/s3-destination-key` |
| Region | us-west-2 |
| Description | KMS key for destination S3 bucket |
| Key Rotation | Enabled |

**Key Policy Statements:**
- Root account full access (`kms:*`)
- Replication role: `Encrypt`, `ReEncrypt*`, `GenerateDataKey*`, `DescribeKey`, `Decrypt`
- S3 Service Principal: `Encrypt`, `ReEncrypt*`, `GenerateDataKey*`, `DescribeKey` (with conditions for destination bucket)

## S3 Replication Configuration

| Property | Value |
|----------|-------|
| Source Bucket | `kms-demo-source-bucket-primary-11111` |
| Destination Bucket | `kms-demo-destination-bucket-secondary-22222` |
| Replication Rule ID | `replication-rule` |
| Status | Enabled |
| Filter | All objects (Prefix: `""`) |
| Priority | 1 |

**Replication Features:**
- **Source Selection Criteria**: `SseKmsEncryptedObjects` - Only replicates KMS-encrypted objects
- **Encryption Configuration**: Objects are re-encrypted using `alias/s3-destination-key` (destination KMS key)
- **Replication Time**: 15 minutes (with metrics enabled)
- **Delete Marker Replication**: Enabled
- **Storage Class**: STANDARD

## Bucket Policies

### Source Bucket Policy
- Allows replication role to read/list objects
- Enforces encryption with source KMS key

### Destination Bucket Policy
- Allows replication role to write replicated objects
- Allows S3 service to put objects encrypted with destination KMS key

## Summary

This infrastructure enables:
- ✅ Automatic cross-region replication of KMS-encrypted S3 objects
- ✅ Each region has its own KMS key for encryption/decryption
- ✅ Centralized IAM role for S3 service to perform replication
- ✅ KMS key rotation enabled for security
- ✅ 15-minute RTC (Replication Time Control) for compliance
- ✅ Delete marker replication for consistency
