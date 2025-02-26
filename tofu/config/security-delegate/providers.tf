provider "aws" {
  alias    = "by_region"
  for_each = toset(["us-east-1", "us-east-2", "us-west-1", "us-west-2"])

  region = each.key

  default_tags {
    tags = {
      project     = "security"
      environment = "production"
    }
  }
}
