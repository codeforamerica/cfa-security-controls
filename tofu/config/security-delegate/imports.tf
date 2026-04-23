# Import existing Security Hub accounts (already enabled outside of IaC).
import {
  for_each = local.regions
  to       = module.security_hub[each.key].aws_securityhub_account.this
  id       = data.aws_caller_identity.current.account_id
}

# Import existing product subscriptions.
# ID format: PRODUCT_ARN,SUBSCRIPTION_ARN
import {
  for_each = {
    for pair in setproduct(
      tolist(local.regions),
      ["aws/guardduty", "aws/inspector", "aws/macie"]
    ) : "${pair[0]}/${pair[1]}" => { region = pair[0], product = pair[1] }
  }
  to = module.security_hub[each.value.region].aws_securityhub_product_subscription.this[each.value.product]
  id = "arn:aws:securityhub:${each.value.region}::product/${each.value.product},arn:aws:securityhub:${each.value.region}:${data.aws_caller_identity.current.account_id}:product-subscription/${each.value.product}"
}

# Import existing standards subscriptions.
import {
  for_each = {
    for pair in setproduct(
      tolist(local.regions),
      ["aws-foundational-security-best-practices/v/1.0.0", "cis-aws-foundations-benchmark/v/1.4.0", "nist-800-53/v/5.0.0"]
    ) : "${pair[0]}/${pair[1]}" => { region = pair[0], standard = pair[1] }
  }
  to = module.security_hub[each.value.region].aws_securityhub_standards_subscription.this[each.value.standard]
  id = "arn:aws:securityhub:${each.value.region}:${data.aws_caller_identity.current.account_id}:subscription/${each.value.standard}"
}
