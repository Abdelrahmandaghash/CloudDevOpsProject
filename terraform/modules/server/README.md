# `terraform/modules/server` — Jenkins EC2 server

> The CI host: an Ubuntu 22.04 `t3.small` instance with SSH access, port 8080 open, and an IAM
> instance profile that allows pushing images to ECR.

## Files

| File | Purpose |
|------|---------|
| `variables.tf` | `vpc_id`, `subnet_id`, `key_name`, `instance_type` (default `t3.small`) |
| `main.tf` | AMI lookup, security group, IAM role/policy/profile, EC2 instance |
| `outputs.tf` | `public_ip` — consumed by `terraform/outputs.tf` as `jenkins_public_ip` |

## Resources

| Resource | Details |
|----------|---------|
| AMI data source | Canonical owner `099720109477`, latest `ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` |
| Security group `jenkins-sg` | Ingress TCP 22 (SSH) and 8080 (Jenkins) from `0.0.0.0/0`; all egress allowed |
| IAM role `jenkins-role` | EC2 assume-role; attached policy `AmazonEC2ContainerRegistryPowerUser` |
| Instance profile `jenkins-profile` | Attaches the role to the instance so AWS CLI can log in to ECR without static keys |
| EC2 instance | `t3.small`, 20 GB root volume, key pair from `var.key_name`, tag `Name = jenkins-server` |

The `Name=jenkins-server` tag is important: the [Ansible dynamic inventory](../../../ansible/aws_ec2.yml)
filters on it to find this machine automatically.

## Interface

| Input | Source |
|-------|--------|
| `vpc_id` | `network.vpc_id` |
| `subnet_id` | `network.public_subnet_ids[0]` |
| `key_name` | root variable passed with `-var key_name=ivolve-key` |

## Related

- [modules overview](../README.md)
- [Ansible roles](../../../ansible/roles/README.md) — configure this instance
- [Jenkins pipelines](../../../jenkins/README.md) — run on this instance
