# 🏗️ Terraform — AWS Infrastructure as Code

> Creates the entire cloud environment: VPC, Jenkins EC2, EKS cluster, ECR repositories, IAM roles
> and the EBS CSI driver. State is stored in S3. Full walkthrough:
> [section 3 of the root README](../README.md#3-terraform--aws-infrastructure).

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `backend.tf` | S3 backend: bucket `ivolve-terraform-state-020139096861`, key `cloud-devops-project/terraform.tfstate`, region `us-east-1` |
| `variables.tf` | `region` (default `us-east-1`), `key_name` (existing EC2 key pair, no default) |
| `main.tf` | Provider `hashicorp/aws ~> 5.0`, AZ data source, four module calls |
| `outputs.tf` | `jenkins_public_ip`, `ecr_urls`, `eks_cluster_name` |
| `.terraform.lock.hcl` | Pins provider versions (aws `5.100.0`, tls `4.4.2`) |
| [modules/](modules/README.md) | [network](modules/network/README.md) · [server](modules/server/README.md) · [eks](modules/eks/README.md) · [ecr](modules/ecr/README.md) |

---

## ✅ Inputs

| Variable | Type / default | Description |
|---|---|---|
| `region` | string / `us-east-1` | AWS region for all resources |
| `key_name` | string / **required** | Name of an existing EC2 key pair used for Jenkins SSH |

---

## 📤 Outputs

| Output | Value |
|---|---|
| `jenkins_public_ip` | `module.server.public_ip` |
| `ecr_urls` | Map of repository name → repository URL |
| `eks_cluster_name` | `ivolve-cluster` |

---

## 🧱 What Gets Created

36 resources: VPC `10.0.0.0/16`, 2 public + 2 private subnets, IGW, NAT Gateway, route tables,
NACL, `jenkins-sg`, IAM roles/instance profile, one `t3.small` EC2, EKS cluster + 2-node group,
OIDC provider, IRSA role, EBS CSI add-on, and three ECR repositories.

---

## 🚀 How to Run

```bash
cd terraform
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan -var key_name=<KEY_PAIR>
terraform apply -var key_name=<KEY_PAIR>
terraform output jenkins_public_ip
terraform output ecr_urls
terraform output eks_cluster_name
```

Destroy (delete the Ingress first so the ELB is released):

```bash
terraform destroy -var key_name=<KEY_PAIR>
```

---

## 🔗 Related

- [Root README](../README.md)
- [Ansible](../ansible/README.md) — consumes `jenkins_public_ip`
- [Architecture deep dive](../docs/architecture.md#2-aws-network)

---

## 👨‍💻 Author

**Abdelrahman Daghash**  
Cloud DevOps Engineer — NTI DevOps Training Program, iVolve Technologies

## 📬 Contact

- 🐙 [GitHub](https://github.com/Abdelrahmandaghash)
- 📧 3bdelrahmandaghash@gmail.com
- 🔗 [Project repository](https://github.com/Abdelrahmandaghash/CloudDevOpsProject)
