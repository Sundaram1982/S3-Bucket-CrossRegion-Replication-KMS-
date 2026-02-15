output "source_bucket" {
  value = module.s3_replication.source_bucket
}

output "destination_bucket" {
  value = module.s3_replication.destination_bucket
}
