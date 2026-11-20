# Terraform saves its state file in an S3 bucket.
# Create this bucket by hand first (AWS Console -> S3 -> Create bucket),
# then put its name below.
terraform {
  backend "s3" {
    bucket = "CHANGE-ME-your-terraform-state-bucket"
    key    = "cloud-devops-project/terraform.tfstate"
    region = "us-east-1"
  }
}
