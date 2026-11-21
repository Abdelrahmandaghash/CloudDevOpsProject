# `argocd/` — GitOps application

> One manifest that tells ArgoCD to deploy everything in `k8s/` from GitHub into the `ivolve`
> namespace, automatically and continuously.

## Contents

| File | Purpose |
|------|---------|
| `application.yaml` | ArgoCD `Application` resource named `ivolve-app` in namespace `argocd` |

## Application specification

| Field | Value |
|-------|-------|
| `metadata.name` | `ivolve-app` |
| `metadata.namespace` | `argocd` |
| `spec.project` | `default` |
| `spec.source.repoURL` | `https://github.com/Abdelrahmandaghash/CloudDevOpsProject.git` |
| `spec.source.targetRevision` | `main` |
| `spec.source.path` | `k8s` |
| `spec.destination.server` | `https://kubernetes.default.svc` (the local cluster) |
| `spec.destination.namespace` | `ivolve` |
| `spec.syncPolicy.automated.prune` | `true` |
| `spec.syncPolicy.automated.selfHeal` | `true` |

With `prune` and `selfHeal` enabled, resources removed from Git are deleted from the cluster and
manual drift is corrected automatically. There is no manual sync step in the normal workflow.

## Installation

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
```

Open the UI and retrieve the initial password:

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
# in another terminal:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

User `admin`, URL `https://localhost:8081`. The application should report **Synced** and **Healthy**.

## The GitOps loop

```
Jenkins pushes a new image tag into k8s/ on GitHub
                │
                ▼
ArgoCD detects the commit on main
                │
                ▼
ivolve-app syncs → new pods roll out in namespace ivolve
```

## Related

- [Root deployment guide](../README.md)
- [Kubernetes manifests](../k8s/README.md)
- [Jenkins pipelines](../jenkins/README.md)
