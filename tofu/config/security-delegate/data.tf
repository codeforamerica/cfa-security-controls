data "aws_caller_identity" "current" {
  provider = aws.by_region[local.primary_region]
}
