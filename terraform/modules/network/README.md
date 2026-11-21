# 🌐 Terraform Network Module — VPC and Subnets

> Builds `ivolve-vpc` (`10.0.0.0/16`), two public and two private subnets, IGW, NAT, route tables and
> a permissive NACL. See [AWS network](../../../docs/architecture.md#2-aws-network).

---

## 📄 Files

| File | Purpose |
|------|---------|
| `variables.tf` | `vpc_cidr`, `azs` (list), `public_subnet_cidrs`, `private_subnet_cidrs` |
| `main.tf` | VPC, subnets, IGW, EIP + NAT, route tables, associations, NACL |
| `outputs.tf` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |

---

## ✅ Inputs

| Variable | Type | Value from root module |
|---|---|---|
| `vpc_cidr` | string | `10.0.0.0/16` |
| `azs` | list(string) | `slice(data.aws_availability_zones.available.names, 0, 2)` |
| `public_subnet_cidrs` | list(string) | `["10.0.1.0/24", "10.0.2.0/24"]` |
| `private_subnet_cidrs` | list(string) | `["10.0.3.0/24", "10.0.4.0/24"]` |

---

## 📤 Outputs

| Output | Description |
|---|---|
| `vpc_id` | Id of `ivolve-vpc` |
| `public_subnet_ids` | Ids of `public-subnet-1`, `public-subnet-2` |
| `private_subnet_ids` | Ids of `private-subnet-1`, `private-subnet-2` |

---

## 🧱 Resources and Rules

| Resource | Details |
|---|---|
| `aws_vpc.main` | DNS hostnames enabled, tag `Name = ivolve-vpc` |
| `aws_subnet.public` ×2 | `map_public_ip_on_launch = true`, tag `kubernetes.io/role/elb = 1` |
| `aws_subnet.private` ×2 | Tag `kubernetes.io/role/internal-elb = 1` |
| `aws_internet_gateway.igw` | `ivolve-igw` |
| `aws_eip.nat` + `aws_nat_gateway.nat` | EIP in `public_subnet_ids[0]`, tag `ivolve-nat` |
| `aws_route_table.public` | `0.0.0.0/0 → igw` |
| `aws_route_table.private` | `0.0.0.0/0 → nat` |
| `aws_network_acl.main` | Ingress/egress rule 100, protocol `-1`, `0.0.0.0/0`, allow; attached to all four subnets |

---

## 🚀 How to Run

Called only from `terraform/main.tf`:

```bash
terraform -chdir=terraform plan -var key_name=<KEY_PAIR>
```

---

## 🔗 Related

- [modules overview](../README.md)
- [Root terraform configuration](../../README.md)
