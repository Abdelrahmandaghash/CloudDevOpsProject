# `terraform/` — AWS infrastructure as code

> Builds the entire cloud environment: VPC and networking, the Jenkins EC2 server, the EKS cluster
> with two worker nodes, three ECR repositories, and the EBS CSI driver with IRSA. The state file is
> stored remotely in S3.

## Contents

| File | Purpose |
|------|---------|
| `backend.tf` | S3 backend configuration: bucket `ivolve-terraform-state-020139096861`, key `cloud-devops-project/terraform.tfstate`, region `us-east-1` |
| `variables.tf` | `region` (default `us-east-1`) and `key_name` (existing EC2 key pair for SSH) |
| `main.tf` | AWS provider, availability-zone lookup, and the four module calls |
| `outputs.tf` | `jenkins_public_ip`, `ecr_urls`, `eks_cluster_name` |
| [modules/](modules/README.md) | [network](modules/network/README.md) · [server](modules/server/README.md) · [eks](modules/eks/README.md) · [ecr](modules/ecr/README.md) |

## What gets created

| Resource | Details |
|----------|---------|
| VPC | `10.0.0.0/16`, DNS hostnames enabled, named `ivolve-vpc` |
| Subnets | 2 public (`10.0.1.0/24`, `10.0.2.0/24`) + 2 private (`10.0.3.0/24`, `10.0.4.0/24`) in the first two AZs |
| Networking | Internet Gateway, one NAT Gateway, public/private route tables, NACLs |
| Jenkins server | Ubuntu 22.04 EC2 `t3.small`, 20 GB disk, security group allowing SSH (22) and Jenkins (8080), IAM role with ECR power-user access |
| EKS cluster | `ivolve-cluster` with managed node group `ivolve-nodes`: 2 × `t3.small`, desired = min = max = 2, in private subnets |
| Storage | `aws-ebs-csi-driver` add-on with an IRSA role for `ebs-csi-controller-sa` |
| ECR | Repositories `frontend`, `auth`, `roadmap`, with `force_delete = true` |
| IAM | Cluster, node and CSI service roles with the required AWS managed policies |

All instance types are **`t3.small`** for free-tier eligibility.

## Usage

Create the S3 bucket (versioning and encryption enabled) and an EC2 key pair first, set the bucket
name in `backend.tf`, then:

```bash
cd terraform
terraform init
terraform validate
terraform plan -var key_name=ivolve-key
terraform apply -var key_name=ivolve-key

# values needed by the next stages:
terraform output jenkins_public_ip
terraform output ecr_urls
terraform output eks_cluster_name
```

Destroy everything at the end:

```bash
terraform destroy -var key_name=ivolve-key
```

The S3 bucket and the key pair are created outside Terraform and are not removed by `destroy`.

## Related

- [Root README](../README.md)
- [Ansible configuration](../ansible/README.md) — consumes `jenkins_public_ip`
- [Kubernetes manifests](../k8s/README.md) — deployed onto `ivolve-cluster`
