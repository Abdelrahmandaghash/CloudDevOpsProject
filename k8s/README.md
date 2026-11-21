# `k8s/` — Kubernetes manifests

> All 13 manifests for the `ivolve` namespace. This folder is the **GitOps source of truth**:
> [`argocd/application.yaml`](../argocd/application.yaml) points at `path: k8s`. Full explanation:
> [section 8.5 of the root README](../README.md#85-kubernetes--manifests-and-exposure).

## Contents

| File | Resource | Key details |
|---|---|---|
| `namespace.yaml` | Namespace `ivolve` | Isolates every application resource |
| `configmap.yaml` | ConfigMap `app-config` | `DB_HOST=mysql-0.mysql`, `DB_PORT=3306`, `DB_NAME=ivolve`, `DB_USER=root`, `AUTH_SERVICE_URL=http://auth:5000`, `ROADMAP_SERVICE_URL=http://roadmap:8080` |
| `secret.yaml` | Secret `app-secret` (Opaque) | `stringData`: `DB_PASSWORD`, `MYSQL_ROOT_PASSWORD` — **values must be replaced, see Security notes** |
| `storageclass.yaml` | StorageClass `ebs-sc` | `ebs.csi.aws.com`, `WaitForFirstConsumer` |
| `mysql-headless-service.yaml` | Service `mysql` | `clusterIP: None`; stable DNS `mysql-0.mysql` |
| `mysql-statefulset.yaml` | StatefulSet `mysql` | `mysql:8`, 1 replica, PVC `data` 1 Gi `ReadWriteOnce`, `subPath: mysql` |
| `frontend-deployment.yaml` | Deployment `frontend` | 1 replica, ECR `frontend:2` (tag maintained by Jenkins), port 3000, `envFrom: app-config` |
| `auth-deployment.yaml` | Deployment `auth` | 1 replica, ECR `auth:2`, port 5000, `envFrom: app-config` + `app-secret` |
| `roadmap-deployment.yaml` | Deployment `roadmap` | 1 replica, ECR `roadmap:2`, port 8080, no config needed |
| `frontend-service.yaml` | Service `frontend` | port 3000 → targetPort 3000 |
| `auth-service.yaml` | Service `auth` | port 5000 → targetPort 5000 |
| `roadmap-service.yaml` | Service `roadmap` | port 8080 → targetPort 8080 |
| `ingress.yaml` | Ingress `frontend-ingress` | `ingressClassName: nginx`, path `/` → `frontend:3000` |

## Inputs / outputs

- **Inputs:** the EBS CSI add-on and OIDC/IRSA role from Terraform; the `ebs-sc` StorageClass;
  ConfigMap/Secret values.
- **Outputs:** four running workloads, three ClusterIP Services, a 1 Gi PVC, and one public ingress
  address.

## Apply order

Normally ArgoCD applies everything. For a manual check:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml -f k8s/secret.yaml -f k8s/storageclass.yaml
kubectl apply -f k8s/mysql-headless-service.yaml -f k8s/mysql-statefulset.yaml
kubectl apply -f k8s/
kubectl get all,pvc,ingress -n ivolve
```

Namespace → config/storage → StatefulSet/headless Service → Deployments/Services → Ingress.

## How data persists

`StatefulSet` → `volumeClaimTemplates[data]` → PVC `data-mysql-0` (1 Gi, `ebs-sc`) → EBS disk created
by `ebs.csi.aws.com`. The `subPath: mysql` mount avoids the `lost+found` initialisation error.

## Related

- [Root README](../README.md)
- [ArgoCD application](../argocd/README.md)
- [Kubernetes architecture diagram](../docs/architecture.md#4-kubernetes-workload-layout)
