data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  results_bucket = "security-macie-results-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  logs_bucket    = "security-macie-logs-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

module "macie" {
  source  = "cloudposse/macie/aws"
  version = "0.1.3"

  # Minimal labeling as we don't use cloudposse label module.
  namespace   = "security"
  environment = "production"
  name        = "macie"

  account_status               = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  providers = {
    aws       = aws
    aws.admin = aws
  }
}

# KMS key for encrypting Macie findings and samples.
resource "aws_kms_key" "macie" {
  description             = "KMS key for Amazon Macie findings and samples"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy = jsonencode(yamldecode(templatefile("${path.module}/templates/kms-key-policy.yaml.tftpl", {
    partition = data.aws_partition.current.partition
    account   = data.aws_caller_identity.current.account_id
  })))
}

resource "aws_kms_alias" "macie" {
  name          = "alias/macie"
  target_key_id = aws_kms_key.macie.key_id
}

# Logging bucket for Macie results bucket.
module "logs" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket = local.logs_bucket

  bucket_policy = jsonencode(yamldecode(templatefile("${path.module}/templates/logs-bucket-policy.yaml.tftpl", {
    partition = data.aws_partition.current.partition
    account   = data.aws_caller_identity.current.account_id
    bucket    = local.logs_bucket
  })))

  lifecycle_configuration = [{
    id     = "logs"
    status = "Enabled"

    filter = {
      prefix = ""
    }

    abort_incomplete_multipart_upload_days = 7

    noncurrent_version_expiration = [{
      noncurrent_days = 30
    }]

    expiration = {
      days = var.logs_retention_period
    }
  }]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = aws_kms_key.macie.arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"
}

# S3 bucket for storing sensitive data discovery results.
module "results" {
  source  = "boldlink/s3/aws"
  version = "2.6.0"

  bucket = local.results_bucket

  bucket_policy = jsonencode(yamldecode(templatefile("${path.module}/templates/results-bucket-policy.yaml.tftpl", {
    partition = data.aws_partition.current.partition
    account   = data.aws_caller_identity.current.account_id
    bucket    = local.results_bucket
  })))

  lifecycle_configuration = [{
    id     = "results"
    status = "Enabled"

    filter = {
      prefix = ""
    }

    abort_incomplete_multipart_upload_days = 7

    noncurrent_version_expiration = [{
      noncurrent_days = 30
    }]

    expiration = {
      days = var.results_retention_period
    }
  }]

  sse_bucket_key_enabled = true
  sse_kms_master_key_arn = aws_kms_key.macie.arn
  sse_sse_algorithm      = "aws:kms"

  versioning_status = "Enabled"

  s3_logging = {
    target_bucket = module.logs.id
    target_prefix = "results/"
  }
}

# Configure Macie to export discovery results to the S3 bucket.
resource "aws_macie2_classification_export_configuration" "results" {
  s3_destination {
    bucket_name = module.results.id
    key_prefix  = "results/"
    kms_key_arn = aws_kms_key.macie.arn
  }

  depends_on = [
    module.results,
    aws_kms_key.macie
  ]
}

data "external" "reveal_configuration" {
  program = [
    "aws", "macie2", "get-reveal-configuration",
    "--query", "{status: configuration.status, kmsKeyId: configuration.kmsKeyId}",
    "--output", "json", "--region", data.aws_region.current.name
  ]
}

# Enable feature to retrieve and reveal sensitive data samples.
# There is no native Terraform resource for this yet.
resource "terraform_data" "reveal" {
  # Trigger when status is not ENABLED or KMS key changes.
  triggers_replace = [
    data.external.reveal_configuration.result.status != "ENABLED" ? "ENABLE" : "STAY",
    data.external.reveal_configuration.result.kmsKeyId != aws_kms_key.macie.key_id ? aws_kms_key.macie.key_id : "SAME"
  ]

  provisioner "local-exec" {
    command = "aws macie2 update-reveal-configuration --configuration status=ENABLED,kmsKeyId=${aws_kms_key.macie.key_id} --region ${data.aws_region.current.name}"
  }
}

data "external" "template_id" {
  program = [
    "aws", "macie2", "list-sensitivity-inspection-templates", "--query",
    "sensitivityInspectionTemplates[?name=='automated-sensitive-data-discovery'] | [0] | {id: id}",
    "--output", "json", "--region", data.aws_region.current.name
  ]
}

resource "terraform_data" "template" {
  depends_on = [data.external.template_id]

  # Trigger replacement when the template file changes.
  triggers_replace = [
    filesha256("${path.module}/template.yaml")
  ]

  provisioner "local-exec" {
    command = "aws macie2 update-sensitivity-inspection-template --id ${data.external.template_id.result.id} --region ${data.aws_region.current.name} --cli-input-yaml file://${path.module}/template.yaml"
  }
}
