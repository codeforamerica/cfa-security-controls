data "aws_region" "current" {}

resource "aws_securityhub_account" "this" {
  auto_enable_controls      = var.auto_enable_controls
  control_finding_generator = "SECURITY_CONTROL"
  enable_default_standards  = false
}

resource "aws_securityhub_standards_subscription" "this" {
  for_each = toset(var.standards)

  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/${each.key}"

  depends_on = [aws_securityhub_account.this]
}
