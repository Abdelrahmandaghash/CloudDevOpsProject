# 🛠️ Jenkins — Continuous Integration Pipelines

> One Jenkins Pipeline per microservice. All three call the same six stages from the
> [`vars/`](../vars/README.md) shared library. Full walkthrough:
> [section 6 of the root README](../README.md#6-jenkins-ci--pipelines-and-shared-library).

---

## 📁 Project Structure

| Folder | Script path | Build context | ECR repository | Manifest updated |
|---|---|---|---|---|
| [frontend/](frontend/README.md) | `jenkins/frontend/Jenkinsfile` | `app/frontend` | `frontend` | `k8s/frontend-deployment.yaml` |
| [auth/](auth/README.md) | `jenkins/auth/Jenkinsfile` | `app/auth-service` | `auth` | `k8s/auth-deployment.yaml` |
| [roadmap/](roadmap/README.md) | `jenkins/roadmap/Jenkinsfile` | `app/roadmap-service` | `roadmap` | `k8s/roadmap-deployment.yaml` |

---

## The six stages

| # | Stage | Shared step | Effect |
|---:|---|---|---|
| 1 | Build Image | `buildImage(IMAGE, FOLDER)` | `docker build -t <ECR>/<service>:<BUILD_NUMBER> <folder>` |
| 2 | Scan Image | `scanImage(IMAGE)` | `trivy image --severity HIGH,CRITICAL <image>` |
| 3 | Push Image | `pushImage(IMAGE, REGISTRY, REGION)` | ECR login + `docker push` |
| 4 | Delete Image Locally | `deleteImage(IMAGE)` | `docker rmi` frees disk on the CI host |
| 5 | Update Manifests | `updateManifests(FILE, IMAGE)` | `sed` replaces the `image:` line |
| 6 | Push Manifests | `pushManifests(REPO)` | `git add k8s`, commit, push `HEAD:main` |

---

## Inputs (per Jenkinsfile)

| Variable | Example value in the files |
|---|---|
| `REGION` | `us-east-1` |
| `REGISTRY` | `020139096861.dkr.ecr.us-east-1.amazonaws.com` — **replace with your account** |
| `IMAGE` | `${REGISTRY}/<service>:${BUILD_NUMBER}` |
| `REPO` | `github.com/Abdelrahmandaghash/CloudDevOpsProject.git` — **replace with your repo** |

---

## 📤 Outputs

| Output | Consumer |
|---|---|
| Image in ECR tagged with the build number | EKS nodes via the Deployments |
| Git commit changing `k8s/<service>-deployment.yaml` | ArgoCD `ivolve-app` |

---

## 🚀 How to Run

1. Register the shared library as **`shared-lib`** (this repository, branch `main`).
2. Add credential ID **`github-creds`** (*Username with password*, PAT with `repo` scope).
3. Create three *Pipeline* jobs with *Pipeline script from SCM* and the script paths above.
4. Click **Build Now** on each job; check the Stage View for six green stages.

---

## 🔗 Related

- [Root README](../README.md)
- [Shared library](../vars/README.md)
- [Ansible tooling role](../ansible/roles/tools/README.md)

---

## 👨‍💻 Author

**Abdelrahman Daghash**  
Cloud DevOps Engineer — NTI DevOps Training Program, iVolve Technologies

## 📬 Contact

- 🐙 [GitHub](https://github.com/Abdelrahmandaghash)
- 📧 3bdelrahmandaghash@gmail.com
- 🔗 [Project repository](https://github.com/Abdelrahmandaghash/CloudDevOpsProject)
