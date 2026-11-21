# `terraform/modules/` — reusable infrastructure modules

> Four modules composed by [`terraform/main.tf`](../main.tf). Each has `variables.tf`, `main.tf` and
> `outputs.tf`.

| Module | Purpose | Inputs | Outputs |
|---|---|---|---|
| [network/](network/README.md) | VPC, 4 subnets, IGW, NAT, route tables, NACL | `vpc_cidr`, `azs`, `public_subnet_cidrs`, `private_subnet_cidrs` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| [server/](server/README.md) | Jenkins EC2, security group, IAM profile | `vpc_id`, `subnet_id`, `key_name`, `instance_type` | `public_ip` |
| [eks/](eks/README.md) | EKS cluster, node group, OIDC, IRSA, EBS CSI | `cluster_name`, `private_subnet_ids` | `cluster_name` |
| [ecr/](ecr/README.md) | Three private repositories | `repo_names` | `repo_urls` |

## Composition

```mermaid
flowchart LR
  AZ[data.aws_availability_zones.available<br/>first 2 names] --> NET[module network]
  NET -->|vpc_id| SVR[module server]
  NET -->|public_subnet_ids 0| SVR
  NET -->|private_subnet_ids| EKS[module eks]
  SVR -->|public_ip| OUT1[output jenkins_public_ip]
  EKS -->|cluster_name| OUT3[output eks_cluster_name]
  ECR[module ecr] -->|repo_urls| OUT2[output ecr_urls]
```

## How to run

You never run a module directly. From `terraform/`:

```bash
terraform init && terraform validate && terraform plan -var key_name=<KEY_PAIR>
```

## Related

- [terraform overview](../README.md)
- [Root deployment guide](../../README.md)
