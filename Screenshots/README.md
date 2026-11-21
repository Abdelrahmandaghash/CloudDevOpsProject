# `Screenshots/` — deployment evidence

> Numbered captures taken while the project was deployed, kept here as proof of each stage of the
> pipeline. They follow the real order of work, from infrastructure to the running application.
> The main README does not embed them; this file is their index.

## Gallery index

| # | File | What it shows |
|---|------|---------------|
| 01 | `01-terraform-apply-complete.png` | `terraform apply` completing — OIDC provider and EBS CSI driver creation |
| 02 | `02-ansible-playbook-success.png` | Ansible `PLAY RECAP` — `ok=13`, `failed=0` |
| 03 | `03-ecr-repositories.png` | The three private ECR repositories in AWS (`frontend`, `auth`, `roadmap`) |
| 04 | `04-eks-nodes-ready.png` | `aws eks update-kubeconfig`, two EKS nodes `Ready`, ingress manifest applied |
| 05 | `05-ingress-nginx-running.png` | ingress-nginx controller resources created in the cluster |
| 06 | `06-jenkins-jobs-created.png` | Jenkins dashboard after creating `auth`, `frontend` and `roadmap` (all `N/A` before the first build) |
| 07 | `07-jenkins-jobs-all-green.png` | Jenkins dashboard with all three jobs successful |
| 08 | `08-jenkins-jobs-overview.png` | Jenkins jobs overview and build history |
| 09 | `09-pipeline-frontend.png` | Frontend pipeline stage view (build #2) |
| 10 | `10-pipeline-auth.png` | Auth pipeline stage view (build #2) |
| 11 | `11-pipeline-roadmap.png` | Roadmap pipeline stage view (build #2) |
| 12 | `12-argocd-install.png` | ArgoCD installation output and `ivolve-app created` |
| 13 | `13-argocd-pods-and-portforward.png` | ArgoCD pods and `kubectl port-forward` to the UI |
| 14 | `14-argocd-application-healthy.png` | `ivolve-app` application tree — `Healthy` and `Synced` |
| 15 | `15-app-login-page.png` | iVolve login page served from the EKS ingress |
| 16 | `16-app-roadmap-page.png` | Authenticated roadmap page ("Welcome, daghash") |

All 16 captures are numbered consecutively and stored in this folder; no raw or rejected images are
included.

## Related

- [Root README](../README.md)
