# `terraform/modules/ecr` — container repositories

> One private ECR repository per microservice. Jenkins pushes build images here; Kubernetes pulls
> from here using the Jenkins EC2 instance role and the EKS node role.

## Files

| File | Purpose |
|------|---------|
| `variables.tf` | `repo_names` — list of repository names |
| `main.tf` | `aws_ecr_repository` resource created for every name |
| `outputs.tf` | `repo_urls` — map of repository name to its URL |

## Repositories

The root module passes:

```hcl
repo_names = ["frontend", "auth", "roadmap"]
```

`force_delete = true` lets `terraform destroy` remove the repositories even when images remain —
useful for a project environment, but something to avoid in production.

The resulting URLs look like:

```
020139096861.dkr.ecr.us-east-1.amazonaws.com/frontend
020139096861.dkr.ecr.us-east-1.amazonaws.com/auth
020139096861.dkr.ecr.us-east-1.amazonaws.com/roadmap
```

These URLs are referenced in the [Jenkinsfiles](../../../jenkins/README.md) and the
[Kubernetes Deployments](../../../k8s/README.md).

## Related

- [modules overview](../README.md)
- [Jenkins push step](../../../vars/README.md)
