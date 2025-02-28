terraform {
  backend "s3" {
    bucket         = "security-production-tfstate-20250226170802389800000001"
    key            = "security-delegate.tfstate"
    region         = "us-east-1"
    dynamodb_table = "production.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=ssl-policy"

  bucket_suffix = true
  project       = "security"
  environment   = "production"
}

# Deploy automation rules to all regions.
module "automations" {
  for_each = toset(["us-east-1", "us-east-2", "us-west-1", "us-west-2"])
  source   = "../../modules/security-hub-automations"

  providers = {
    aws = aws.by_region[each.key]
  }
}

# Configure Macie in each region.
module "macie" {
  for_each = toset(["us-east-1", "us-east-2", "us-west-1", "us-west-2"])
  source   = "../../modules/macie"

  providers = {
    aws = aws.by_region[each.key]
  }
}
