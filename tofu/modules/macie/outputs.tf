output "template_id" {
  value       = data.external.template_id.result.id
  description = "The ID of the Macie2 sensitivity inspection template."
}
