# `Screenshots/` — deployment evidence

> Numbered captures taken while the project was deployed, kept here as proof of each stage of the
> pipeline. The main README does not embed them; this file is their index.

## Gallery index

| # | File | What it shows |
|---|------|---------------|
| 01 | `01-terraform-apply-complete.png` | `terraform apply` completing with all resources and outputs |
| 02 | `02-ansible-playbook-success.png` | Ansible `PLAY RECAP` with `failed=0` |
| 03 | `03-ecr-repositories.png` | The three private ECR repositories in AWS |
| 04 | `04-eks-nodes-ready.png` | kubeconfig update, `kubectl get nodes` and ingress installation |
| 05 | `05-ingress-nginx-running.png` | ingress-nginx controller pods running |
| 06 | `06-jenkins-jobs-all-green.png` | The three Jenkins jobs, all successful |
| 07 | `07-pipeline-frontend.png` | Frontend pipeline, all stages green |
| 08 | `08-pipeline-auth.png` | Auth pipeline, all stages green |
| 09 | `09-pipeline-roadmap.png` | Roadmap pipeline, all stages green |
| 10 | `10-argocd-install.png` | ArgoCD installation and `ivolve-app` creation |
| 11 | `11-argocd-application-healthy.png` | `ivolve-app` showing Synced / Healthy |
| 12 | `12-ingress-elb-and-pods.png` | Ingress Load Balancer address and running pods |
| 13 | `13-app-login-page.png` | Application login page served from EKS |
| 14 | `14-troubleshooting-gpg-failure.png` | GPG key error encountered during setup (before the fix) |
| 15 | `15-troubleshooting-free-tier-error.png` | Instance-type/free-tier error encountered during setup (before the fix) |

The unnumbered raw captures are kept in `rejected/` locally and are not part of the repository.

## Related

- [Root README](../README.md)
