data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "external" "reveal_configuration" {
  program = [
    "aws", "macie2", "get-reveal-configuration",
    "--query", "{status: configuration.status, kmsKeyId: configuration.kmsKeyId}",
    "--output", "json", "--region", data.aws_region.current.name
  ]
}

data "external" "template_id" {
  program = [
    "aws", "macie2", "list-sensitivity-inspection-templates", "--query",
    "sensitivityInspectionTemplates[?name=='automated-sensitive-data-discovery'] | [0] | {id: id}",
    "--output", "json", "--region", data.aws_region.current.name
  ]
}
