#!/usr/bin/env bash
# Imports existing GuardDuty detectors and features into OpenTofu state.
# Run from tofu/config/security-delegate/ after tofu init.
set -euo pipefail

regions=(us-east-1 us-east-2 us-west-1 us-west-2)

for region in "${regions[@]}"; do
  echo "==> Importing GuardDuty resources in $region..."

  id=$(aws guardduty list-detectors --region "$region" \
    --query 'DetectorIds[0]' --output text)

  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector.this" "$id"
  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.ebs_malware_protection" "$id/EBS_MALWARE_PROTECTION"
  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.eks_audit_logs" "$id/EKS_AUDIT_LOGS"
  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.lambda_protection" "$id/LAMBDA_NETWORK_LOGS"
  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.rds_protection" "$id/RDS_LOGIN_EVENTS"
  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.runtime_monitoring" "$id/RUNTIME_MONITORING"
  tofu import "module.guardduty[\"$region\"].aws_guardduty_detector_feature.s3_data_events" "$id/S3_DATA_EVENTS"
done

echo "==> Done."
