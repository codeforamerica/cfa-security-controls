terraform {
  backend "s3" {
    bucket         = "security-production-tfstate-20250226170802389800000001"
    key            = "security-delegate.tfstate"
    region         = "us-east-1"
    dynamodb_table = "production.tfstate"
  }
}

module "backend" {
  source = "github.com/codeforamerica/tofu-modules-aws-backend?ref=1.1.1"

  bucket_suffix = true
  project       = "security"
  environment   = "production"
}

# Configure Security Hub in each region.
module "security_hub" {
  for_each = local.regions
  source   = "../../modules/security-hub"

  providers = {
    aws = aws.by_region[each.key]
  }
}

# Deploy automation rules to all regions.
module "automations" {
  for_each = local.regions
  source   = "../../modules/security-hub-automations"

  providers = {
    aws = aws.by_region[each.key]
  }
}

# Configure GuardDuty in each region.
# Run scripts/import-guardduty.sh before the first apply.
module "guardduty" {
  for_each = local.regions
  source   = "../../modules/guardduty"

  providers = {
    aws = aws.by_region[each.key]
  }
}

# Configure Amazon Inspector in each region.
module "inspector" {
  for_each = local.regions
  source   = "../../modules/inspector"

  providers = {
    aws = aws.by_region[each.key]
  }
}

# Configure Macie in each region.
module "macie" {
  for_each = local.regions
  source   = "../../modules/macie"

  providers = {
    aws = aws.by_region[each.key]
  }
}

# Cross-region aggregation: aggregate findings from all linked regions into the primary region.
# Run scripts/import-security-hub.sh before the first apply.
resource "aws_securityhub_finding_aggregator" "this" {
  provider          = aws.by_region[local.primary_region]
  linking_mode      = "SPECIFIED_REGIONS"
  specified_regions = setsubtract(local.regions, [local.primary_region])

  depends_on = [module.security_hub]
}
