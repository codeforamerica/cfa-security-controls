locals {
  definitions = yamldecode(file("${path.module}/rules/definitions.yaml"))
}
