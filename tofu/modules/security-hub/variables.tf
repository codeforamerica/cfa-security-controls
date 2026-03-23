variable "auto_enable_controls" {
  description = "Whether to automatically enable new controls when they are added to a subscribed standard."
  type        = bool
  default     = true
}

variable "products" {
  description = "AWS Security Hub product integrations to subscribe to. Each value should be the product path (e.g., 'aws/guardduty')."
  type        = list(string)
  default     = ["aws/guardduty"]
}

variable "standards" {
  description = "Security Hub standards to subscribe to. Each value should be the standard path without the 'standards/' prefix (e.g., 'aws-foundational-security-best-practices/v/1.0.0')."
  type        = list(string)
  default = [
    "aws-foundational-security-best-practices/v/1.0.0",
    "cis-aws-foundations-benchmark/v/1.4.0",
    "nist-800-53/v/5.0.0",
  ]
}
