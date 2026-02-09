provider "aws" {
  region = var.source_region
}

provider "aws" {
  alias  = "dr"
  region = var.destination_region
}
