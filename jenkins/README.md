# `jenkins/` — continuous integration pipelines

> One Jenkins Pipeline per microservice. All three use the same reusable stages from the
> [`vars/`](../vars/README.md) shared library, build an image per build number, scan it with Trivy,
> push it to ECR and publish the new tag back to GitHub for ArgoCD.

## Contents

| Folder | Build context | ECR repository | Manifest updated |
|--------|---------------|----------------|------------------|
| [frontend/](frontend/README.md) | `app/frontend` | `frontend` | `k8s/frontend-deployment.yaml` |
| [auth/](auth/README.md) | `app/auth-service` | `auth` | `k8s/auth-deployment.yaml` |
| [roadmap/](roadmap/README.md) | `app/roadmap-service` | `roadmap` | `k8s/roadmap-deployment.yaml` |

## Pipeline stages

Every Jenkinsfile runs the same six stages:

| # | Stage | Shared-library step | Result |
|---|-------|--------------------|--------|
| 1 | Build Image | `buildImage` | Docker image tagged `<ECR>/<service>:<BUILD_NUMBER>` |
| 2 | Scan Image | `scanImage` | Trivy reports HIGH/CRITICAL findings |
| 3 | Push Image | `pushImage` | ECR login via AWS CLI, then `docker push` |
| 4 | Delete Image Locally | `deleteImage` | Frees disk space on the Jenkins host |
| 5 | Update Manifests | `updateManifests` | `sed` replaces the `image:` line in the service Deployment |
| 6 | Push Manifests | `pushManifests` | Git commit + push to `main`, using `github-creds` |

## Environment in every Jenkinsfile

```groovy
@Library('shared-lib') _
REGION   = 'us-east-1'
REGISTRY = '020139096861.dkr.ecr.us-east-1.amazonaws.com'
IMAGE    = "${REGISTRY}/<service>:${BUILD_NUMBER}"
REPO     = 'github.com/Abdelrahmandaghash/CloudDevOpsProject.git'
```

The image tag is the **Jenkins build number**, so each deployment maps to a specific CI run.

## Job setup in Jenkins

Create three *Pipeline* jobs named `frontend`, `auth`, `roadmap`, each
*Pipeline script from SCM → Git → this repository*, with the Script Path pointing at the matching
`jenkins/<service>/Jenkinsfile`. Register the shared library as **`shared-lib`** in
*Manage Jenkins → System → Global Trusted Pipeline Libraries*, and add a username/password
credential with ID **`github-creds`** containing your GitHub user and a PAT with `repo` scope.

## End-to-end flow

```
git push / Build Now
        │
        ▼
Jenkins: build → scan → push ECR → update k8s YAML → push to GitHub
                                                          │
                                                          ▼
                                     ArgoCD auto-sync → EKS rolling update
```

## Related

- [Root README](../README.md)
- [Ansible configuration](../ansible/README.md) — installs Docker, Trivy, AWS CLI on the Jenkins host
- [Shared library](../vars/README.md)
- [Kubernetes manifests](../k8s/README.md)
