data "aws_region" "current" {}

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

output "template_id" {
  value = data.external.template_id.result.id
}
