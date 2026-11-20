resource "aws_ecr_repository" "repo" {
  for_each     = toset(var.repo_names)
  name         = each.value
  force_delete = true
}
