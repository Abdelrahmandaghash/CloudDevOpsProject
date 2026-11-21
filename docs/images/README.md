# 🖼️ Documentation Images — Screenshot Manifest

This folder is the image library used by the documentation. Every image embedded in the
[root README](../../README.md) or in [architecture.md](../architecture.md) is listed below with the
**exact filename**, what it must prove, and the command or page to capture it from.

> **Status:** the 16 captures below already exist. They are curated copies of the numbered files in
> [`Screenshots/`](../../Screenshots/README.md). After you rebuild the stack, recapture each view
> and overwrite the same filename — the documentation links will keep working. If you cannot
> recapture a view, leave the existing file in place and add a note to your project report.

---

## 🏗️ Architecture Diagram

The end-to-end architecture illustration is embedded in the [root README](../../README.md) and the main
component READMEs. Keep the editable SVG as the source of truth and export the PNG whenever it changes.

| Exact filename | Format | Purpose |
|---|---|---|
| `project-architecture.svg` | Editable SVG | Source diagram — grouped draw.io/AWS-style view of the real project stack |
| `project-architecture.png` | PNG (1600 × 1075) | Rendered image embedded by `README.md` and the component READMEs |

---

## 📸 Required Captures

| # | Exact filename | What it must show | Capture from |
|---:|---|---|---|
| 01 | `01-terraform-apply-complete.png` | `terraform apply` finishing; OIDC provider and EBS CSI driver resources being created | `terraform apply -var key_name=<KEY_PAIR>` output in `terraform/` |
| 02 | `02-ansible-playbook-success.png` | Ansible `PLAY RECAP` with `ok=13` and `failed=0` | `ansible-playbook playbook.yml` output in `ansible/` |
| 03 | `03-ecr-repositories.png` | The three private repositories `frontend`, `auth`, `roadmap` | AWS Console → Amazon ECR → Private registry → Repositories |
| 04 | `04-eks-nodes-ready.png` | `aws eks update-kubeconfig`, then two nodes with status `Ready` | `aws eks update-kubeconfig --name ivolve-cluster --region us-east-1` and `kubectl get nodes` |
| 05 | `05-ingress-nginx-running.png` | ingress-nginx Deployment, DaemonSet and Service created in `ingress-nginx` | `kubectl get all -n ingress-nginx` after applying the controller manifest |
| 06 | `06-jenkins-jobs-created.png` | Jenkins dashboard listing `auth`, `frontend`, `roadmap` with `N/A` results | `http://<JENKINS_PUBLIC_IP>:8080` before the first build |
| 07 | `07-jenkins-jobs-all-green.png` | Same three jobs, all with a green/successful last build | Jenkins dashboard after the first three builds |
| 08 | `08-jenkins-jobs-overview.png` | Jenkins job list / build history overview | Jenkins dashboard → build history view |
| 09 | `09-pipeline-frontend.png` | Frontend pipeline Stage View with all six stages green | Jenkins → `frontend` → Stage View (build #2 or later) |
| 10 | `10-pipeline-auth.png` | Auth pipeline Stage View with all six stages green | Jenkins → `auth` → Stage View |
| 11 | `11-pipeline-roadmap.png` | Roadmap pipeline Stage View with all six stages green | Jenkins → `roadmap` → Stage View |
| 12 | `12-argocd-install.png` | ArgoCD install output and `application.argoproj.io/ivolve-app created` | `kubectl apply -n argocd -f <install.yaml>` and `kubectl apply -f argocd/application.yaml` |
| 13 | `13-argocd-pods-and-portforward.png` | ArgoCD pods `Running` and the active `kubectl port-forward` session | `kubectl get pods -n argocd` and `kubectl port-forward svc/argocd-server -n argocd 8081:443` |
| 14 | `14-argocd-application-healthy.png` | `ivolve-app` tree showing `Healthy` and `Synced` | ArgoCD UI → `ivolve-app` application tree |
| 15 | `15-app-login-page.png` | iVolve login page rendered through the ingress address | Browser → `http://<INGRESS_ADDRESS>/login` |
| 16 | `16-app-roadmap-page.png` | Authenticated roadmap page with "Welcome, <username>" and eight cards | Browser → `http://<INGRESS_ADDRESS>/roadmap` after login |

---

## 📸 Optional Evidence

These are useful for a reviewer but are not required by the documentation. Add them with the exact
filenames below if you have time.

| Exact filename | What it must show | Capture from |
|---|---|---|
| `17-vpc-topology.png` | VPC with 2 public and 2 private subnets across two AZs | AWS Console → VPC → Your VPCs → `ivolve-vpc` |
| `18-security-groups.png` | `jenkins-sg` inbound rules 22 and 8080 | AWS Console → EC2 → Security Groups → `jenkins-sg` |
| `19-nacl-rules.png` | `ivolve-nacl` inbound and outbound rule 100 | AWS Console → VPC → Network ACLs → `ivolve-nacl` |
| `20-iam-roles.png` | `jenkins-role`, `ebs-csi-controller-role`, OIDC provider | AWS Console → IAM → Roles / Identity providers |
| `21-trivy-scan.png` | Trivy HIGH/CRITICAL scan table from a pipeline console | Jenkins → any job → Scan Image stage output |
| `22-pvc-bound.png` | The 1 Gi `data` PVC bound to the MySQL pod | `kubectl get pvc,pv -n ivolve` |
| `23-pod-env-config.png` | Non-secret environment injected into the `auth` pod | `kubectl exec -n ivolve deploy/auth -- env \| grep DB_` |
| `24-cost-explorer.png` | Daily cost after the stack was up | AWS Console → Cost Explorer |
| `25-destroy-complete.png` | `terraform destroy` completing with `Destroy complete!` | `terraform destroy -var key_name=<KEY_PAIR>` |
| `26-github-repository.png` | GitHub repository landing page showing the folder list and rendered README — used as the placeholder in [section 1](../../README.md#1-github-repository-setup) | Browser → `https://github.com/<YOUR_USER>/CloudDevOpsProject` |

> **Do not capture** the raw contents of `k8s/secret.yaml`, the Jenkins credential values, the ArgoCD
> initial admin password, or a GitHub PAT. Redact them in any terminal recording.
