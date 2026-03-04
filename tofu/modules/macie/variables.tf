variable "results_retention_period" {
  type        = number
  description = <<-EOT
    Number of days to retain Macie sensitive data discovery results. Must be
    between `1` and `3653` (10 years). Defaults to `365` (1 year).
    EOT
  default     = 365

  validation {
    condition     = var.results_retention_period > 0 && var.results_retention_period < 3654
    error_message = "Retention period must be between 1 and 3653."
  }
}

variable "logs_retention_period" {
  type        = number
  description = <<-EOT
    Number of days to retain Macie results access logs. Must be between `1` and
    `3653` (10 years). Defaults to `1095` (3 years).
    EOT
  default     = 1095

  validation {
    condition     = var.logs_retention_period > 0 && var.logs_retention_period < 3654
    error_message = "Retention period must be between 1 and 3653."
  }
}
