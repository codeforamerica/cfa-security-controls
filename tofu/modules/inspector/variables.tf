variable "resource_types" {
  description = <<-EOT
    Resource types to enable Amazon Inspector scanning for. Valid values: EC2,
    ECR, LAMBDA, LAMBDA_CODE.
    EOT
  type        = list(string)
  default     = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]

  validation {
    condition     = length(setsubtract(toset(var.resource_types), toset(["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]))) == 0
    error_message = "Valid resource types are: EC2, ECR, LAMBDA, LAMBDA_CODE."
  }
}
