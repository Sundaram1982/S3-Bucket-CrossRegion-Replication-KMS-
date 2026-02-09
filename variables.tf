variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "source_region" {
  type = string
}

variable "destination_region" {
  type = string
}

variable "source_bucket_name" {
  type = string
}

variable "destination_bucket_name" {
  type = string
}
