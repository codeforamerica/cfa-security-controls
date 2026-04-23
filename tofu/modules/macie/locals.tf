locals {
  results_bucket = "security-macie-results-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
  logs_bucket    = "security-macie-logs-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}
