# 🖥️ Terraform Server Module — Jenkins EC2

> Creates the CI host: Ubuntu 22.04 `t3.small`, 20 GB disk, SSH and Jenkins ports open, and an IAM
> instance profile that can push to ECR without stored AWS keys.

---

## 📄 Files

| File | Purpose |
|------|---------|
| `variables.tf` | `vpc_id`, `subnet_id`, `key_name`, `instance_type` (default `t3.small`) |
| `main.tf` | AMI data source, `jenkins-sg`, IAM role/policy/profile, EC2 instance |
| `outputs.tf` | `public_ip` |

---

## ✅ Inputs

| Variable | Source in `main.tf` |
|---|---|
| `vpc_id` | `module.network.vpc_id` |
| `subnet_id` | `module.network.public_subnet_ids[0]` |
| `key_name` | root variable `-var key_name=<KEY_PAIR>` |
| `instance_type` | default `t3.small` (do not change for free tier) |

---

## 📤 Outputs

| Output | Used by |
|---|---|
| `public_ip` | `terraform/outputs.tf` → `jenkins_public_ip` → Ansible / Jenkins UI URL |

---

## 🧱 Resources and Rules

| Resource | Details |
|---|---|
| `data.aws_ami.ubuntu` | Owner `099720109477`, `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` |
| `aws_security_group.jenkins` | Ingress tcp 22 and tcp 8080 from `0.0.0.0/0`; egress all |
| `aws_iam_role.jenkins` | EC2 assume-role policy |
| `aws_iam_role_policy_attachment.ecr` | `AmazonEC2ContainerRegistryPowerUser` |
| `aws_iam_instance_profile.jenkins` | `jenkins-profile` |
| `aws_instance.jenkins` | `t3.small`, 20 GB root volume, tag `Name = jenkins-server` |

The `Name=jenkins-server` tag is what [`ansible/aws_ec2.yml`](../../../ansible/aws_ec2.yml) filters
on. The public IP changes after every `apply` — never hard-code it.

---

## 🚀 How to Run

```bash
terraform -chdir=terraform output jenkins_public_ip
ssh -i <KEY_PAIR>.pem ubuntu@<JENKINS_PUBLIC_IP>
```

---

## 🔗 Related

- [modules overview](../README.md)
- [Ansible configuration](../../../ansible/README.md)
