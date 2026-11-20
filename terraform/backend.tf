# Terraform saves its state file in an S3 bucket.
# Bucket created 20 Nov 2026 via: aws s3api create-bucket --bucket ivolve-terraform-state-020139096861 --region us-east-1
# (versioning + encryption enabled). Name below.
terraform {
  backend "s3" {
    bucket = "ivolve-terraform-state-020139096861"
    key    = "cloud-devops-project/terraform.tfstate"
    region = "us-east-1"
  }
}
