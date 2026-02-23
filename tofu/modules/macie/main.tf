data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

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
    aws.admin = aws
  }
}

# KMS key for encrypting Macie findings and samples.
resource "aws_kms_key" "macie" {
  description             = "KMS key for Amazon Macie findings and samples"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.macie_kms.json
}

resource "aws_kms_alias" "macie" {
  name          = "alias/macie"
  target_key_id = aws_kms_key.macie.key_id
}

data "aws_iam_policy_document" "macie_kms" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "Allow Macie to use the key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["macie.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = ["*"]
  }
}

# S3 bucket for storing sensitive data discovery results.
resource "aws_s3_bucket" "results" {
  bucket = "security-macie-results-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

# Logging bucket for Macie results bucket.
resource "aws_s3_bucket" "logs" {
  bucket = "security-macie-logs-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "results" {
  bucket = aws_s3_bucket.results.id
  versioning_configuration {
    status = "ENABLED"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "ENABLED"
  }
}

resource "aws_s3_bucket_logging" "results" {
  bucket = aws_s3_bucket.results.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "results/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "results" {
  bucket = aws_s3_bucket.results.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.macie.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "results" {
  bucket = aws_s3_bucket.results.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "results" {
  bucket = aws_s3_bucket.results.id
  policy = data.aws_iam_policy_document.results_bucket_policy.json
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.logs_bucket_policy.json
}

data "aws_iam_policy_document" "logs_bucket_policy" {
  statement {
    sid    = "Allow S3 Logging"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.logs.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_iam_policy_document" "results_bucket_policy" {
  statement {
    sid    = "Allow Macie to write results"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["macie.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.results.arn,
      "${aws_s3_bucket.results.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# Configure Macie to export discovery results to the S3 bucket.
resource "aws_macie2_classification_export_configuration" "results" {
  s3_destination {
    bucket_name = aws_s3_bucket.results.bucket
    key_prefix  = "results/"
    kms_key_arn = aws_kms_key.macie.arn
  }

  depends_on = [
    aws_s3_bucket_policy.results,
    aws_kms_key.macie
  ]
}

# Enable feature to retrieve and reveal sensitive data samples.
resource "aws_macie2_reveal_configuration" "reveal" {
  status     = "ENABLED"
  kms_key_id = aws_kms_key.macie.key_id
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
