module "s3" {
  source = "./modules/s3_module"

  project_name            = var.project_name
  source_bucket_name      = var.source_bucket_name
  destination_bucket_name = var.destination_bucket_name

  providers = {
    aws    = aws
    aws.dr = aws.dr
  }
}