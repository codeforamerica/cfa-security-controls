output "detector_id" {
  value       = aws_guardduty_detector.this.id
  description = "The ID of the GuardDuty detector."
}
