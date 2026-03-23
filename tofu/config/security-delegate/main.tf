terraform {
  backend "s3" {
    bucket         = "security-production-tfstate-20250226170802389800000001"
    key            = "security-delegate.tfstate"
    region         = "us-east-1"
    dynamodb_table = "production.tfstate"
  }
}

locals {
  primary_region = "us-east-1"
  regions        = toset(["us-east-1", "us-east-2", "us-west-1", "us-west-2"])
}

data "aws_caller_identity" "current" {
  provider = aws.by_region[local.primary_region]
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
# To import existing detectors and features (detector IDs are region-specific UUIDs):
#   for region in us-east-1 us-east-2 us-west-1 us-west-2; do
#     id=$(aws guardduty list-detectors --region $region --query 'DetectorIds[0]' --output text)
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector.this" $id
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.ebs_malware_protection" "$id/EBS_MALWARE_PROTECTION"
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.eks_audit_logs" "$id/EKS_AUDIT_LOGS"
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.lambda_protection" "$id/LAMBDA_NETWORK_LOGS"
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.rds_protection" "$id/RDS_LOGIN_EVENTS"
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.runtime_monitoring" "$id/RUNTIME_MONITORING"
#     tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.s3_data_events" "$id/S3_DATA_EVENTS"
#   done
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
# To import the existing aggregator, get its ARN first:
#   aws securityhub list-finding-aggregators --region us-east-1 \
#     --query 'FindingAggregators[0].FindingAggregatorArn' --output text
# Then run:
#   tofu import 'aws_securityhub_finding_aggregator.this' '<ARN>'
resource "aws_securityhub_finding_aggregator" "this" {
  provider          = aws.by_region[local.primary_region]
  linking_mode      = "SPECIFIED_REGIONS"
  specified_regions = setsubtract(local.regions, [local.primary_region])

  depends_on = [module.security_hub]
}


############ IMPORT EXISTING RESOURCES ############

# Import existing Security Hub accounts (already enabled outside of IaC).
import {
  for_each = local.regions
  to       = module.security_hub[each.key].aws_securityhub_account.this
  id       = data.aws_caller_identity.current.account_id
}

# Import existing product subscriptions.
# ID format: PRODUCT_ARN,SUBSCRIPTION_ARN
import {
  for_each = {
    for pair in setproduct(
      tolist(local.regions),
      ["aws/guardduty", "aws/inspector", "aws/macie"]
    ) : "${pair[0]}/${pair[1]}" => { region = pair[0], product = pair[1] }
  }
  to = module.security_hub[each.value.region].aws_securityhub_product_subscription.this[each.value.product]
  id = "arn:aws:securityhub:${each.value.region}::product/${each.value.product},arn:aws:securityhub:${each.value.region}:${data.aws_caller_identity.current.account_id}:product-subscription/${each.value.product}"
}

# Import existing standards subscriptions.
import {
  for_each = {
    for pair in setproduct(
      tolist(local.regions),
      ["aws-foundational-security-best-practices/v/1.0.0", "cis-aws-foundations-benchmark/v/1.4.0", "nist-800-53/v/5.0.0"]
    ) : "${pair[0]}/${pair[1]}" => { region = pair[0], standard = pair[1] }
  }
  to = module.security_hub[each.value.region].aws_securityhub_standards_subscription.this[each.value.standard]
  id = "arn:aws:securityhub:${each.value.region}:${data.aws_caller_identity.current.account_id}:subscription/${each.value.standard}"
}
