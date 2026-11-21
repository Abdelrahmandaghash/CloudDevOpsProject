# `k8s/` — Kubernetes manifests

> All 13 manifests for the `ivolve` namespace. They are the **GitOps source of truth**: ArgoCD
> watches this folder in GitHub and applies every change to EKS automatically.

## Contents

### Namespace and configuration

| File | Resource | Purpose |
|------|----------|---------|
| `namespace.yaml` | Namespace `ivolve` | Isolates all application resources |
| `configmap.yaml` | ConfigMap `app-config` | `DB_HOST=mysql-0.mysql`, `DB_PORT=3306`, `DB_NAME=ivolve`, `DB_USER=root`, `AUTH_SERVICE_URL=http://auth:5000`, `ROADMAP_SERVICE_URL=http://roadmap:8080` |
| `secret.yaml` | Secret `app-secret` (Opaque) | `DB_PASSWORD` and `MYSQL_ROOT_PASSWORD` via `stringData` |

### Storage

| File | Resource | Purpose |
|------|----------|---------|
| `storageclass.yaml` | StorageClass `ebs-sc` | `ebs.csi.aws.com` provisioner, `WaitForFirstConsumer`; uses the EBS CSI driver installed by Terraform |
| `mysql-statefulset.yaml` | StatefulSet `mysql` | MySQL 8, 1 replica, 1 Gi `ReadWriteOnce` PVC on `ebs-sc`, mounted at `/var/lib/mysql` |
| `mysql-headless-service.yaml` | Service `mysql` | `clusterIP: None` — gives the database the stable DNS name `mysql-0.mysql` |

### Application workloads

| File | Resource | Image / port |
|------|----------|--------------|
| `frontend-deployment.yaml` | Deployment `frontend` (1 replica) | `…/frontend:latest`, port 3000, config from `app-config` |
| `auth-deployment.yaml` | Deployment `auth` (1 replica) | `…/auth:latest`, port 5000, config from `app-config` + `app-secret` |
| `roadmap-deployment.yaml` | Deployment `roadmap` (1 replica) | `…/roadmap:latest`, port 8080 |

The `:latest` tags are placeholders: Jenkins replaces the whole `image:` line with a build-number
tag on every successful pipeline run.

### Services and ingress

| File | Resource | Purpose |
|------|----------|---------|
| `frontend-service.yaml` | Service `frontend` | ClusterIP, 3000 → 3000 |
| `auth-service.yaml` | Service `auth` | ClusterIP, 5000 → 5000 |
| `roadmap-service.yaml` | Service `roadmap` | ClusterIP, 8080 → 8080 |
| `ingress.yaml` | Ingress `frontend-ingress` | `ingressClassName: nginx`, path `/` → `frontend:3000`, backed by an AWS Load Balancer |

## Apply order

Normally you do **not** apply this folder by hand — [ArgoCD](../argocd/README.md) does it.
For a manual check:

```bash
kubectl apply -f k8s/
kubectl get all,ingress -n ivolve
kubectl get pvc -n ivolve
```

## Related

- [Root deployment guide](../README.md)
- [ArgoCD application](../argocd/README.md)
- [Jenkins manifest update step](../vars/README.md)
