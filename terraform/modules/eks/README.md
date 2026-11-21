# `terraform/modules/eks` — EKS cluster, nodes and storage

> Creates `ivolve-cluster`, a fixed 2-node group in the private subnets, the cluster OIDC provider,
> and an IRSA role for the EBS CSI controller so MySQL can get an EBS disk.

## Files

| File | Purpose |
|------|---------|
| `variables.tf` | `cluster_name`, `private_subnet_ids` |
| `main.tf` | IAM roles, cluster, node group, OIDC provider, IRSA trust, EBS CSI add-on |
| `outputs.tf` | `cluster_name` |

## Inputs / Output

| Input | Source |
|---|---|
| `cluster_name` | `ivolve-cluster` in root `main.tf` |
| `private_subnet_ids` | `module.network.private_subnet_ids` |

| Output | Value |
|---|---|
| `cluster_name` | `aws_eks_cluster.this.name` |

## Resources

| Resource | Details |
|---|---|
| `aws_iam_role.cluster` | Trust `eks.amazonaws.com`, policy `AmazonEKSClusterPolicy` |
| `aws_eks_cluster.this` | Control plane in the two private subnets |
| `aws_iam_role.nodes` | Trust `ec2.amazonaws.com`; policies: WorkerNode, CNI, ECR ReadOnly, EBS CSI |
| `aws_eks_node_group.this` | `ivolve-nodes`, `t3.small`, `desired = min = max = 2`, private subnets |
| `aws_iam_openid_connect_provider.this` | Client `sts.amazonaws.com`, thumbprint from `data.tls_certificate.oidc` |
| `aws_iam_role.ebs_csi` | `ebs-csi-controller-role`, trusts SA `kube-system:ebs-csi-controller-sa` |
| `aws_eks_addon.ebs_csi` | `aws-ebs-csi-driver`, `service_account_role_arn` = IRSA role, depends on node group |

## How to run

```bash
terraform -chdir=terraform output eks_cluster_name
aws eks update-kubeconfig --name ivolve-cluster --region us-east-1
kubectl get nodes
kubectl get pods -n kube-system | grep ebs-csi
```

## Related

- [modules overview](../README.md)
- [StorageClass and StatefulSet](../../../k8s/README.md)
- [IRSA explanation](../../../docs/architecture.md#6-data-and-identity-flow)
