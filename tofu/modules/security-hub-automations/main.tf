locals {
  definitions = yamldecode(file("${path.module}/rules/definitions.yaml"))
}

resource "aws_securityhub_automation_rule" "rules" {
  for_each = { for rule in local.definitions.Rules : rule.RuleName => rule }

  rule_name   = each.value.RuleName
  description = each.value.Description
  rule_order  = each.value.RuleOrder
  is_terminal = each.value.IsTerminal
  rule_status = each.value.RuleStatus

  dynamic "actions" {
    for_each = each.value.Actions
    content {
      type = actions.value.Type

      finding_fields_update {
        note {
          text       = actions.value.FindingFieldsUpdate.Note.Text
          updated_by = actions.value.FindingFieldsUpdate.Note.UpdatedBy
        }

        verification_state = lookup(actions.value.FindingFieldsUpdate, "VerificationState", null)



        workflow {
          status = actions.value.FindingFieldsUpdate.Workflow.Status
        }
      }
    }
  }

  criteria {
    dynamic "compliance_security_control_id" {
      for_each = each.value.Criteria.ComplianceSecurityControlId

      content {
        comparison = compliance_security_control_id.value.Comparison
        value      = compliance_security_control_id.value.Value
      }
    }

    dynamic "compliance_status" {
      for_each = each.value.Criteria.ComplianceStatus

      content {
        comparison = compliance_status.value.Comparison
        value      = compliance_status.value.Value
      }
    }

    dynamic "product_name" {
      for_each = each.value.Criteria.ProductName

      content {
        comparison = product_name.value.Comparison
        value      = product_name.value.Value
      }
    }

    dynamic "record_state" {
      for_each = each.value.Criteria.RecordState

      content {
        comparison = record_state.value.Comparison
        value      = record_state.value.Value
      }
    }

    dynamic "resource_tags" {
      for_each = each.value.Criteria.ResourceTags

      content {
        comparison = resource_tags.value.Comparison
        key        = resource_tags.value.Key
        value      = resource_tags.value.Value
      }
    }

    dynamic "workflow_status" {
      for_each = each.value.Criteria.WorkflowStatus

      content {
        comparison = workflow_status.value.Comparison
        value      = workflow_status.value.Value
      }
    }
  }
}
