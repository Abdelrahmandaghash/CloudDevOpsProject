# `terraform/modules/` — reusable infrastructure modules

> Four small, independently testable modules composed by [`terraform/main.tf`](../main.tf).

| Module | Purpose | Key inputs | Key outputs |
|--------|---------|-----------|-------------|
| [network/](network/README.md) | VPC, subnets, IGW, NAT, route tables, NACLs | `vpc_cidr`, `azs`, public/private CIDR lists | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |
| [server/](server/README.md) | Jenkins EC2, security group, IAM instance profile | `vpc_id`, `subnet_id`, `key_name` | `public_ip` |
| [eks/](eks/README.md) | EKS cluster, managed node group, EBS CSI IRSA | `cluster_name`, `private_subnet_ids` | `cluster_name` |
| [ecr/](ecr/README.md) | Container repositories for the three services | `repo_names` | `repo_urls` |

## Composition in `main.tf`

```
network  ──public_subnet_ids[0]──> server   ──public_ip──> terraform output
    │
    └──private_subnet_ids────────> eks      ──cluster_name──> terraform output

repo_names ["frontend","auth","roadmap"] ──> ecr ──repo_urls──> terraform output
```

The availability zones come from the `aws_availability_zones` data source: the first two are used,
which gives the cluster worker nodes one subnet in each of two AZs.

## Related

- [terraform overview](../README.md)
- [Root README](../../README.md)
