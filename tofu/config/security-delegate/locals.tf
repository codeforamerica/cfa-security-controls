locals {
  primary_region = "us-east-1"
  regions        = toset(["us-east-1", "us-east-2", "us-west-1", "us-west-2"])
}
