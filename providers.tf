provider "aws" {
  region = var.source_region
}

provider "aws" {
  alias  = "dest"
  region = var.destination_region
}

