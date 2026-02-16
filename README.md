# S3 Replication with KMS Encryption

## Module Overview

This Terraform module automates the deployment of **secure, cross-region S3 replication with KMS encryption**. It enables organizations to replicate S3 objects from a source bucket in one AWS region to a destination bucket in another region, with all objects encrypted using region-specific KMS keys.

## Module Purpose

This module solves the challenge of setting up encrypted S3 cross-region replication by:
- Creating and configuring source and destination S3 buckets with versioning and encryption
- Establishing region-specific KMS keys with proper encryption context
- Setting up IAM roles and policies that allow S3 service to perform secure replication
- Configuring S3 replication rules that only replicate KMS-encrypted objects
- Re-encrypting objects at the destination using the destination region's KMS key
- Enforcing least-privilege access through carefully scoped KMS and S3 bucket policies

## Key Functionality

### 1. **Cross-Region Replication**
- Automatically replicates S3 objects from source bucket (us-east-1) to destination bucket (us-west-2)
- Supports selective replication based on object encryption type
- Includes delete marker replication for consistency

### 2. **KMS Encryption Management**
- Creates separate KMS keys for each region (source and destination)
- Implements secure key policies with proper principals and conditions
- Enables key rotation for enhanced security
- Handles re-encryption during replication (decrypt with source key, encrypt with destination key)

### 3. **IAM Access Control**
- Creates dedicated IAM role (`s3-replication-role-kms`) for S3 service
- Grants minimal required permissions for reading from source and writing to destination
- Includes both S3 service principal and replication role permissions for complete coverage

### 4. **Replication Configuration**
- Filters for KMS-encrypted objects only (via `SseKmsEncryptedObjects` selection criteria)
- Specifies destination KMS key for re-encryption during replication
- Enables Replication Time Control (RTC) with 15-minute threshold
- Enables replication metrics for monitoring
- Supports delete marker replication

## Features Deployed

✅ KMS keys (source and destination) with proper policies
✅ IAM role (s3-replication-role-kms) and policy
✅ S3 buckets with versioning and encryption
✅ S3 replication configuration with KMS encryption support
✅ Bucket policies for source and destination
✅ KMS aliases for easy key reference
✅ Object Lock enabled on both buckets
✅ Lifecycle policies for automated object management

## Use Cases

- **Disaster Recovery**: Maintain encrypted backups in a different AWS region
- **Data Residency**: Replicate data to comply with regional data storage requirements
- **Multi-Region Analytics**: Distribute encrypted data for analysis across regions
- **Backup & Compliance**: Automated encrypted backups with audit trail support
- **High Availability**: Distribute workloads across regions with encrypted data