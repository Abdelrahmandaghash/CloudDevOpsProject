variable "region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "Name of an existing EC2 key pair (to SSH into Jenkins)"
  type        = string
}
