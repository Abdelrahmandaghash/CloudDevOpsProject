# `terraform/modules/eks` — Kubernetes cluster and storage

> Creates `ivolve-cluster`, its two-node managed worker group, the OIDC provider and the EBS CSI
> driver with an IRSA role so MySQL's PVC can be provisioned on AWS EBS.

## Files

| File | Purpose |
|------|---------|
| `variables.tf` | `cluster_name`, `private_subnet_ids` |
| `main.tf` | Cluster/service roles, EKS cluster, node group, OIDC provider, IRSA role, EBS CSI add-on |
| `outputs.tf` | `cluster_name` |

## Resources

| Resource | Details |
|----------|---------|
| Cluster role | `AmazonEKSClusterPolicy` |
| EKS cluster | `ivolve-cluster`, control plane placed in the supplied private subnets |
| Node role | `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEBSCSIDriverPolicy` |
| Node group | `ivolve-nodes`, `t3.small`, private subnets in two AZs, desired = min = max = **2** |
| OIDC provider | Built from the cluster issuer URL, TLS certificate thumbprint, client `sts.amazonaws.com` |
| IRSA role | `ebs-csi-controller-role`, trusts `system:serviceaccount:kube-system:ebs-csi-controller-sa`, attached `AmazonEBSCSIDriverPolicy` |
| Add-on | `aws-ebs-csi-driver`, configured with `service_account_role_arn` of the IRSA role; depends on the node group and policy attachment |

The IRSA configuration is what allows the CSI controller to create EBS volumes without node-level
AWS credentials. The [`ebs-sc` StorageClass](../../../k8s/storageclass.yaml) uses its provisioner,
`ebs.csi.aws.com`.

## Interface

| Input | Source |
|-------|--------|
| `cluster_name` | `ivolve-cluster` in `main.tf` |
| `private_subnet_ids` | `network.private_subnet_ids` |

## Related

- [modules overview](../README.md)
- [StorageClass and MySQL StatefulSet](../../../k8s/README.md)
- [EKS connection steps in the root guide](../../../README.md)
