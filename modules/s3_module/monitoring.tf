resource "aws_cloudwatch_metric_alarm" "replication_failure" {
  alarm_name          = "S3ReplicationFailure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedReplicationOperations"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    BucketName = aws_s3_bucket.source.bucket
  }
}
