variable "auto_enable_controls" {
  description = <<-EOT
    Whether to automatically enable new controls when they are added to a
    subscribed standard.
    EOT
  type        = bool
  default     = true
}

variable "products" {
  description = <<-EOT
    AWS Security Hub product integrations to subscribe to. Each value should be
    the product path (e.g., 'aws/guardduty').
    EOT
  type        = list(string)
  default = [
    "aws/guardduty",
    "aws/inspector",
    "aws/macie",
  ]
}

variable "standards" {
  description = <<-EOT
    Security Hub standards to subscribe to. Each value should be the standard
    path without the 'standards/' prefix (e.g.,
    'aws-foundational-security-best-practices/v/1.0.0').
    EOT
  type        = list(string)
  default = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "cis-aws-foundations-benchmark/v/1.4.0",
    "nist-800-53/v/5.0.0",
  ]
}
