# CloudDevOpsProject

> **NTI Final Project** — a complete GitOps delivery pipeline for the **iVolve** training platform.
> **Docker** packages the app, **Terraform** builds the AWS infrastructure, **Ansible** configures the Jenkins server,
> **Jenkins** builds & scans the images, and **ArgoCD** deploys them to **Amazon EKS** — automatically, on every push.

![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?logo=terraform&logoColor=white&style=flat-square)
![Ansible](https://img.shields.io/badge/Ansible-Config-EE0000?logo=ansible&logoColor=white&style=flat-square)
![Docker](https://img.shields.io/badge/Docker-Containers-2496ED?logo=docker&logoColor=white&style=flat-square)
![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS-326CE5?logo=kubernetes&logoColor=white&style=flat-square)
![Jenkins](https://img.shields.io/badge/Jenkins-CI%2FCD-D24939?logo=jenkins&logoColor=white&style=flat-square)
![ArgoCD](https://img.shields.io/badge/ArgoCD-GitOps-EF7B4D?logo=argo&logoColor=white&style=flat-square)
![AWS](https://img.shields.io/badge/AWS-us--east--1-FF9900?logo=amazon-aws&logoColor=black&style=flat-square)
![Docs](https://img.shields.io/badge/documentation-complete-2EA44F?logo=readme&logoColor=white&style=flat-square)

**Repository:** https://github.com/Abdelrahmandaghash/CloudDevOpsProject

---

## Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Repository map](#repository-map)
- [NTI task coverage](#nti-task-coverage)
- [Prerequisites](#prerequisites)
- [Step-by-step deployment guide](#step-by-step-deployment-guide)
- [Verification commands](#verification-commands)
- [Clean up](#clean-up)
- [Cost notes](#cost-notes)

---

## Overview

This project takes the **iVolve** application from source code to a live, self-healing deployment on Kubernetes:

1. The application is made of three independent microservices, each with its own Dockerfile.
2. A single `docker-compose.yml` runs the whole stack locally, database included.
3. Terraform creates the complete AWS environment: VPC, Jenkins EC2, EKS cluster, ECR repositories and S3 state backend.
4. Ansible turns the empty Jenkins EC2 into a fully equipped CI server (Java, Jenkins, Docker, AWS CLI, Trivy).
5. Jenkins builds each image, scans it for vulnerabilities, pushes it to ECR, and writes the new image tag back into the Kubernetes manifests in GitHub.
6. ArgoCD watches those manifests and syncs the cluster automatically — Git is the single source of truth.

### The application

| Service | Technology | Port | Responsibility |
|---------|-----------|------|----------------|
| `frontend` | Node.js 22 / Express 5 / EJS | 3000 | Web UI; proxies calls to the two APIs |
| `auth` | Python 3.12 / Flask 3 | 5000 | Signup & login; the only service that uses MySQL |
| `roadmap` | Java 21 / Spring Boot 3.5 | 8080 | Serves the DevOps roadmap data |
| `mysql` | MySQL 8 (StatefulSet + EBS) | 3306 | Persistent database for the auth service |

### The platform

| Layer | Tool | What it does here |
|-------|------|-------------------|
| Containerization | Docker, Compose | Builds images; runs the app locally |
| Infrastructure | Terraform | VPC, subnets, NAT, Jenkins EC2, EKS (2 nodes / 2 AZs), ECR, EBS CSI via IRSA |
| Configuration | Ansible | Java 21, Jenkins, Docker, Git, AWS CLI, Trivy on the Jenkins server |
| Continuous integration | Jenkins + shared library | 6-stage pipeline per microservice |
| Security | Trivy | Scans images for HIGH/CRITICAL vulnerabilities before pushing |
| Orchestration | Kubernetes (EKS) | Runs all four workloads in the `ivolve` namespace |
| Ingress | ingress-nginx | Single AWS Load Balancer exposing the frontend |
| GitOps | ArgoCD | Auto-syncs `k8s/` from GitHub into the cluster |

---

## Architecture

```
 Developer ──push──> GitHub repo <───────────────┐
                         │                        │  Jenkins writes the new
                         │ 1. Jenkins pipeline    │  image tag into k8s/*.yaml
                         ▼                        │
    ┌──────────── Jenkins (EC2 t3.small) ────────┘
    │  Build → Trivy scan → Push ECR → Delete local image
    │                      → Update manifests → Push manifests
    │                      │
    │                      ▼ 2. images stored in
    │              AWS ECR (frontend / auth / roadmap)
    │
    └─ 3. ArgoCD (inside EKS) watches k8s/ in GitHub
                 │  and syncs the cluster automatically
                 ▼
    ┌────────────── AWS VPC 10.0.0.0/16 ──────────────────────┐
    │ Public subnets (2 AZs) : Jenkins EC2, NAT GW, Load Balancer
    │ Private subnets (2 AZs): EKS worker nodes (t3.small × 2)
    │
    │   namespace "ivolve":
    │     Ingress (nginx) ──> frontend ──> auth ──> MySQL
    │                             └─────> roadmap
    │                                      (StatefulSet + EBS 1 Gi)
    └──────────────────────────────────────────────────────────┘
```

---

## Repository map

Every folder has its own README with a complete description of its contents.

| Folder | Contains | Details |
|--------|----------|---------|
| [`app/`](app/README.md) | The three microservice source trees | [frontend](app/frontend/README.md) · [auth](app/auth-service/README.md) · [roadmap](app/roadmap-service/README.md) |
| [`terraform/`](terraform/README.md) | Infrastructure code + S3 backend | [modules](terraform/modules/README.md): [network](terraform/modules/network/README.md) · [server](terraform/modules/server/README.md) · [eks](terraform/modules/eks/README.md) · [ecr](terraform/modules/ecr/README.md) |
| [`ansible/`](ansible/README.md) | Dynamic inventory, playbook, roles | [roles](ansible/roles/README.md): [java](ansible/roles/java/README.md) · [jenkins](ansible/roles/jenkins/README.md) · [tools](ansible/roles/tools/README.md) |
| [`jenkins/`](jenkins/README.md) | One pipeline per service | [frontend](jenkins/frontend/README.md) · [auth](jenkins/auth/README.md) · [roadmap](jenkins/roadmap/README.md) |
| [`vars/`](vars/README.md) | Jenkins shared-library steps | build, scan, push, delete, update & push manifests |
| [`k8s/`](k8s/README.md) | All 13 Kubernetes manifests | namespace, workloads, services, storage, config, ingress |
| [`argocd/`](argocd/README.md) | ArgoCD Application manifest | `ivolve-app`, automated sync |
| [`Screenshots/`](Screenshots/README.md) | Deployment evidence gallery | numbered step-by-step captures |

---

## NTI task coverage

| # | Requirement | Where it is implemented |
|---|-------------|-------------------------|
| **1** | GitHub repository with README and delivered link | this repository |
| **2** | Docker Compose builds & tests app + DB locally | [`docker-compose.yml`](docker-compose.yml), [`app/`](app/README.md) |
| **3** | Terraform: network, server, EKS (2 nodes / 2 AZs), ECR, S3 backend | [`terraform/`](terraform/README.md) |
| **4** | Ansible: roles + dynamic inventory for the Jenkins EC2 | [`ansible/`](ansible/README.md) |
| **5** | Kubernetes: namespace, Deployments, Services, StatefulSet, headless Service, StorageClass, ConfigMap, Secret, Ingress | [`k8s/`](k8s/README.md) |
| **6** | Jenkins: one pipeline per service, shared library | [`jenkins/`](jenkins/README.md), [`vars/`](vars/README.md) |
| **7** | ArgoCD syncs and deploys the app | [`argocd/`](argocd/README.md) |
| **8** | Documentation: setup + architecture | this README and the per-folder READMEs |

---

## Prerequisites

All commands below are written as they were executed on **WSL (Ubuntu 24.04)**.

```bash
sudo apt update
sudo apt install -y git curl unzip python3-pip

pip install boto3
ansible-galaxy collection install amazon.aws

# Install Docker, Terraform, kubectl and AWS CLI v2 from their official sources,
# then configure the AWS credentials/profile used by Terraform and Ansible:
aws configure
```

You also need:

- an **AWS account** with permission to create VPC, EC2, EKS, ECR, IAM and S3 resources;
- a **GitHub account** and a **Personal Access Token** with `repo` scope;
- an existing **EC2 key pair** name (used for SSH to the Jenkins server).

> **Free tier:** every EC2 instance type in this project is `t3.small` — keep it that way.

---

## Step-by-step deployment guide

### Step 1 — Create the GitHub repository

1. Create a repository named `CloudDevOpsProject` on GitHub and clone it.
2. Copy this project into the clone (including the hidden `.gitignore`).
3. Push the first commit:

```bash
git add .
git commit -m "Initial commit: full DevOps pipeline"
git push
```

### Step 2 — Run the application locally (before touching AWS)

```bash
docker compose up --build
```

Compose builds all three images and starts MySQL first, waits for its healthcheck, then starts
`auth`, `roadmap` and `frontend`. Open **http://localhost** and sign up / log in to check that the
frontend, auth service and database talk to each other. Stop with `docker compose down`
(add `-v` to delete the database volume).

### Step 3 — Prepare the S3 backend and key pair

```bash
# Bucket for the Terraform state (use a globally unique name)
aws s3api create-bucket --bucket ivolve-terraform-state-020139096861 --region us-east-1
aws s3api put-bucket-versioning \
  --bucket ivolve-terraform-state-020139096861 \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket ivolve-terraform-state-020139096861 \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Key pair for SSH access to the Jenkins EC2
aws ec2 create-key-pair --key-name ivolve-key \
  --query 'KeyMaterial' --output text > ~/ivolve-key.pem
chmod 400 ~/ivolve-key.pem
```

Set the bucket name in [`terraform/backend.tf`](terraform/backend.tf). Then replace the example
AWS account ID (`020139096861`) and GitHub username (`Abdelrahmandaghash`) in:

- `k8s/*-deployment.yaml` (ECR image URLs),
- `jenkins/*/Jenkinsfile` (ECR registry and repository URL),
- `argocd/application.yaml` (Git repository URL).

Commit and push those changes before continuing.

### Step 4 — Create the AWS infrastructure with Terraform

```bash
cd terraform
terraform init
terraform apply -var key_name=ivolve-key
```

This creates **36 resources** in about 15 minutes: the VPC, two public and two private subnets,
an Internet Gateway, NAT Gateway, the Jenkins EC2 with its IAM role, the EKS cluster and its two
`t3.small` worker nodes, the EBS CSI driver with IRSA, and three ECR repositories.

Save the outputs — you need the Jenkins IP and ECR URLs in the following steps:

```bash
terraform output jenkins_public_ip
terraform output ecr_urls
terraform output eks_cluster_name
```

### Step 5 — Configure the Jenkins server with Ansible

The dynamic inventory finds the instance tagged `Name=jenkins-server` automatically. Set the path
to your `.pem` file in [`ansible/ansible.cfg`](ansible/ansible.cfg), then:

```bash
cd ansible
ansible-inventory --graph
ansible-playbook playbook.yml
```

The playbook installs Java 21, Jenkins, Docker, Git, AWS CLI and Trivy, then starts and enables
Jenkins and Docker. A successful run ends with `failed=0` in the `PLAY RECAP`.

Get the initial admin password and open the UI:

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
```

Browse to `http://<JENKINS_PUBLIC_IP>:8080` and log in with user `admin`.

### Step 6 — Connect kubectl and install the ingress controller

```bash
aws eks update-kubeconfig --name ivolve-cluster --region us-east-1
kubectl get nodes     # two nodes, Ready

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/aws/deploy.yaml
kubectl get pods -n ingress-nginx
```

### Step 7 — Configure Jenkins in the web UI

1. Install the **suggested plugins** and complete the setup wizard.
2. **Manage Jenkins → Credentials → Add Credentials**: kind *Username with password*,
   ID exactly **`github-creds`**, username = your GitHub user, password = your PAT (`repo` scope).
3. **Manage Jenkins → System → Global Trusted Pipeline Libraries**: add a library named **`shared-lib`**,
   Git, this repository URL. The library code lives in `vars/`.
4. Create three **Pipeline** jobs: `frontend`, `auth`, `roadmap`. For each choose
   *Pipeline script from SCM → Git → this repository*, and set the Script Path:

   | Job | Script path |
   |-----|-------------|
   | `frontend` | `jenkins/frontend/Jenkinsfile` |
   | `auth` | `jenkins/auth/Jenkinsfile` |
   | `roadmap` | `jenkins/roadmap/Jenkinsfile` |

5. Click **Build Now** on each job.

Each run performs six stages: **Build Image → Scan Image → Push Image → Delete Image Locally →
Update Manifests → Push Manifests**. The last stage commits the new image tag into `k8s/` on GitHub.

### Step 8 — Install ArgoCD and create the application

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
```

`ivolve-app` now watches the `k8s/` folder on `main`, deploys into the `ivolve` namespace, and
automatically prunes and self-heals drifting resources.

Open the UI:

```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443
# in another terminal:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Log in at `https://localhost:8081` with user `admin` and that password.

### Step 9 — Open the application

```bash
kubectl get ingress -n ivolve
kubectl get pods -n ivolve
```

Copy the `ADDRESS` of `frontend-ingress` into a browser. The frontend, auth service, roadmap
service and MySQL pods should all be `Running`. From here on, every Jenkins build updates an image
tag on GitHub and ArgoCD rolls out the new version without any manual intervention.

---

## Verification commands

| Check | Command | Expected result |
|-------|---------|-----------------|
| Infrastructure | `cd terraform && terraform output` | Jenkins IP, ECR URLs, cluster name |
| Server setup | `cd ansible && ansible-playbook playbook.yml --check` | no failed tasks |
| Jenkins jobs | Jenkins dashboard | `frontend`, `auth`, `roadmap` green |
| Cluster | `kubectl get nodes` | 2 nodes `Ready` |
| Workloads | `kubectl get pods -n ivolve` | 4 pods `Running` |
| Ingress | `kubectl get ingress -n ivolve` | nginx Load Balancer address |
| GitOps | ArgoCD UI → `ivolve-app` | `Synced` and `Healthy` |
| Application | open the ingress address | iVolve login / roadmap pages |

---

## Clean up

Destroy the infrastructure when you are finished to avoid AWS charges. Delete the ingress first so
the Load Balancer is released cleanly:

```bash
kubectl delete ingress --all -n ivolve
cd terraform
terraform destroy -var key_name=ivolve-key
```

The S3 state bucket and the EC2 key pair are created outside Terraform and remain available for a
future deployment.

---

## Cost notes

All compute is free-tier-eligible **`t3.small`**: one Jenkins EC2 and two EKS worker nodes, plus
the EKS control plane, NAT Gateway, Load Balancer, EBS volumes, ECR and S3. Expect roughly
**$0.30–0.40 per hour** while the stack is up — run `terraform destroy` when you are done.

---

*Built for the NTI Final Project · iVolve Technologies × National Telecommunication Institute*
