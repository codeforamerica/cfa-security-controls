variable "enable_ec2_agent_management" {
  description = <<-EOT
    Whether to automatically manage the GuardDuty security agent on EC2
    instances (requires runtime monitoring).
    EOT
  type        = bool
  default     = true
}

variable "enable_eks_addon_management" {
  description = <<-EOT
    Whether to automatically manage the GuardDuty security agent add-on for EKS
    clusters (requires runtime monitoring).
    EOT
  type        = bool
  default     = true
}

variable "enable_eks_audit_logs" {
  description = <<-EOT
    Whether to enable Kubernetes audit log monitoring.
    EOT
  type        = bool
  default     = true
}

variable "enable_lambda_protection" {
  description = <<-EOT
    Whether to enable Lambda network activity monitoring.
    EOT
  type        = bool
  default     = true
}

variable "enable_malware_protection" {
  description = <<-EOT
    Whether to enable malware protection scanning for EC2 EBS volumes.
    EOT
  type        = bool
  default     = true
}

variable "enable_rds_protection" {
  description = <<-EOT
    Whether to enable RDS login activity monitoring.
    EOT
  type        = bool
  default     = true
}

variable "enable_runtime_monitoring" {
  description = <<-EOT
    Whether to enable runtime monitoring for EKS and EC2.
    EOT
  type        = bool
  default     = true
}

variable "enable_s3_logs" {
  description = <<-EOT
    Whether to enable S3 data event monitoring.
    EOT
  type        = bool
  default     = true
}

variable "finding_publishing_frequency" {
  description = <<-EOT
    Frequency of notifications for non-archived findings. Valid values:
    FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS.
    EOT
  type        = string
  default     = "FIFTEEN_MINUTES"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.finding_publishing_frequency)
    error_message = "Must be one of: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS."
  }
}
