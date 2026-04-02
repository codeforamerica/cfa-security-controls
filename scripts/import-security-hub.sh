#!/usr/bin/env bash
# Imports the existing Security Hub finding aggregator into OpenTofu state.
# Run from tofu/config/security-delegate/ after tofu init.
set -euo pipefail

echo "==> Importing Security Hub finding aggregator..."

arn=$(aws securityhub list-finding-aggregators --region us-east-1 \
  --query 'FindingAggregators[0].FindingAggregatorArn' --output text)

tofu import 'aws_securityhub_finding_aggregator.this' "$arn"

echo "==> Done."
