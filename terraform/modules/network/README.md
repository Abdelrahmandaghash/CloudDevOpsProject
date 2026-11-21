# `terraform/modules/network` — VPC and networking

> Creates the isolated network in which the Jenkins server and the EKS cluster live.

## Files

| File | Purpose |
|------|---------|
| `variables.tf` | `vpc_cidr`, `azs`, `public_subnet_cidrs`, `private_subnet_cidrs` |
| `main.tf` | VPC, 4 subnets, Internet Gateway, NAT Gateway, route tables, NACL |
| `outputs.tf` | `vpc_id`, `public_subnet_ids`, `private_subnet_ids` |

## Resources

| Resource | Details |
|----------|---------|
| VPC | `ivolve-vpc`, `10.0.0.0/16`, DNS hostnames enabled |
| Public subnets | `10.0.1.0/24`, `10.0.2.0/24` — `map_public_ip_on_launch = true`, tag `kubernetes.io/role/elb = 1` |
| Private subnets | `10.0.3.0/24`, `10.0.4.0/24` — tag `kubernetes.io/role/internal-elb = 1` |
| Internet Gateway | `ivolve-igw`, attached to the VPC; public route table points to it |
| NAT Gateway | `ivolve-nat` in public subnet 0 with an Elastic IP; private route table points to it |
| NACL | Allow-all ingress and egress (rule 100) across all four subnets |
| Associations | 2 public + 2 private route-table associations |

The Kubernetes ELB tags let the AWS Load Balancer Controller / ingress-nginx place load balancers in
the correct subnets.

## Interface

| Input | Example |
|-------|---------|
| `vpc_cidr` | `10.0.0.0/16` |
| `azs` | first two AZs from `aws_availability_zones` |
| `public_subnet_cidrs` | `["10.0.1.0/24","10.0.2.0/24"]` |
| `private_subnet_cidrs` | `["10.0.3.0/24","10.0.4.0/24"]` |

Outputs are consumed by the `server` module (a public subnet) and the `eks` module (private subnets).

## Related

- [modules overview](../README.md)
- [Root terraform configuration](../../README.md)
