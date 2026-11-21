# 📦 Terraform ECR Module — Container Repositories

> One private ECR repository per microservice. Jenkins pushes images here; EKS nodes pull from here.

---

## 📄 Files

| File | Purpose |
|------|---------|
| `variables.tf` | `repo_names` — list of repository names |
| `main.tf` | `aws_ecr_repository.repo` with `for_each = toset(var.repo_names)`, `force_delete = true` |
| `outputs.tf` | `repo_urls` — map of name → `repository_url` |

---

## ✅ Inputs and Outputs

| Input | Value from root |
|---|---|
| `repo_names` | `["frontend", "auth", "roadmap"]` |

| Output | Description |
|---|---|
| `repo_urls` | URLs used by the Jenkinsfiles and the Kubernetes Deployments |

`force_delete = true` lets `terraform destroy` remove repositories that still contain images. This is
convenient for a project environment but unsafe in production.

---

## 🚀 How to Run

```bash
terraform -chdir=terraform output ecr_urls
aws ecr describe-repositories --region us-east-1 \
  --query 'repositories[].repositoryName' --output table
```

---

## 🔗 Related

- [modules overview](../README.md)
- [Jenkins push step](../../../vars/README.md)
- [Image URLs in Deployments](../../../k8s/README.md)
