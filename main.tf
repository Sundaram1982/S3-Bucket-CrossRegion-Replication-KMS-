module "s3_replication" {
  source = "./modules/s3_module"

  providers = {
    aws      = aws
    aws.dest = aws.dest
  }

  source_bucket_name      = var.bucket_name_source
  destination_bucket_name = var.bucket_name_destination
  source_region           = var.source_region
  destination_region      = var.destination_region
}