# `argocd/` — GitOps application

> One manifest that tells ArgoCD to deploy everything in `k8s/` from GitHub into the `ivolve`
> namespace, automatically and continuously. Full walkthrough:
> [section 8.7 of the root README](../README.md#87-argocd--gitops-delivery).

## Contents

| File | Purpose |
|------|---------|
| `application.yaml` | ArgoCD `Application` resource `ivolve-app` in namespace `argocd` |

## Application specification (inputs)

| Field | Value in the file |
|---|---|
| `metadata.name` | `ivolve-app` |
| `metadata.namespace` | `argocd` |
| `spec.project` | `default` |
| `spec.source.repoURL` | `https://github.com/Abdelrahmandaghash/CloudDevOpsProject.git` — **replace with your repo** |
| `spec.source.targetRevision` | `main` |
| `spec.source.path` | `k8s` |
| `spec.destination.server` | `https://kubernetes.default.svc` |
| `spec.destination.namespace` | `ivolve` |
| `spec.syncPolicy.automated.prune` | `true` |
| `spec.syncPolicy.automated.selfHeal` | `true` |

## Outputs (what you get)

| Result | Check |
|---|---|
| All 13 manifests applied in `ivolve` | `kubectl get all,pvc,ingress -n ivolve` |
| Automatic drift correction | scale a Deployment manually and watch ArgoCD revert it |
| Git commit → deployment | pipeline push appears as a new sync in the UI |

## How to run

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
kubectl get application ivolve-app -n argocd
kubectl port-forward svc/argocd-server -n argocd 8081:443
# second terminal — do not paste this password into docs or tickets:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Open `https://localhost:8081`, user `admin`. Expected status: **Synced** and **Healthy**.

## Related

- [Root README](../README.md)
- [Kubernetes manifests](../k8s/README.md)
- [GitOps sequence diagram](../docs/architecture.md#3-cicd-sequence)
