# CloudDevOpsProject

A full DevOps pipeline for the iVolve application: the code is containerized with **Docker**, the AWS infrastructure is built with **Terraform**, the Jenkins server is configured with **Ansible**, the app runs on **Kubernetes (EKS)**, images are built by **Jenkins**, and deployments are done automatically by **ArgoCD**.

## Architecture overview

```
 Developer ──push──> GitHub repo <───────────────┐
                        │                        │ 4. Jenkins pushes the new
                        │ 1. Jenkins pipeline    │    image name into k8s/ files
                        ▼                        │
   ┌──────────── Jenkins (EC2) ─────────────────┘
   │  Build image -> Scan (Trivy) -> Push -> Delete local image
   │                      │
   │                      ▼ 2. image stored in
   │                 AWS ECR (frontend, auth, roadmap)
   │
   └─ 3. ArgoCD (inside EKS) watches the k8s/ folder in GitHub
                │ and deploys any change automatically
                ▼
   ┌────────────── AWS VPC ──────────────────────────────┐
   │ Public subnets : Jenkins EC2, NAT, Load Balancer     │
   │ Private subnets: EKS worker node 1 (AZ-a)            │
   │                  EKS worker node 2 (AZ-b)            │
   │   namespace "ivolve":                                │
   │     Ingress -> frontend -> auth -> MySQL            │
   │                  └──────> roadmap                   │
   │                                      (StatefulSet + EBS disk)
   └──────────────────────────────────────────────────────┘
```

| Tool | What it does in this project |
|------|------------------------------|
| Docker / docker-compose | Runs the app + database on your laptop |
| Terraform | Creates VPC, Jenkins server, EKS cluster, ECR repositories |
| Ansible | Installs Java, Jenkins, Docker, Trivy on the Jenkins server |
| Kubernetes | Runs the frontend, auth, roadmap and database |
| Jenkins | Builds, scans and pushes images, updates the YAML files |
| ArgoCD | Deploys whatever is in the `k8s/` folder to the cluster |

## Folder structure

```
CloudDevOpsProject/
├── app/              application source code (frontend, auth, roadmap)
├── docker-compose.yml
├── terraform/        modules: network, server, eks, ecr  (+ S3 backend)
├── ansible/          inventory (dynamic), playbook, roles: java, jenkins, tools
├── k8s/              all Kubernetes YAML files
├── jenkins/          Jenkinsfile for frontend, auth and roadmap
├── vars/             Jenkins shared library
├── argocd/           ArgoCD application
└── README.md
```

## Setup instructions

### Requirements (install on your laptop)
Git, Docker, Terraform, Ansible (+ `pip install boto3` and `ansible-galaxy collection install amazon.aws`), AWS CLI (`aws configure` with your keys), kubectl.

### Step 1 - GitHub repository
1. On GitHub create a repository called **CloudDevOpsProject** with a README.
2. `git clone` it, copy this project into it.
3. Clone the iVolve source code and copy `frontend`, `auth-service` and `roadmap-service` into `app/`.
4. `git add .`, `git commit -m "first commit"`, `git push`.

### Step 2 - Run locally with Docker
```
docker compose up --build
```
Open http://localhost. Stop with `docker compose down`.
*(Check the ports and variable names in `docker-compose.yml` match your app.)*

### Step 3 - Create the AWS infrastructure (Terraform)
1. In the AWS Console create an **S3 bucket** (for the state file) and an **EC2 key pair**; download the `.pem` file.
2. Write the bucket name in `terraform/backend.tf`.
3. Run:
```
cd terraform
terraform init
terraform apply -var key_name=YOUR_KEY_PAIR_NAME
```
(`init` downloads plugins, `apply` creates everything - it takes ~15 minutes.)
4. Note the outputs: the Jenkins IP and the two ECR URLs.

### Step 4 - Configure Jenkins server (Ansible)
1. Put the `.pem` path in `ansible/ansible.cfg`.
2. Run:
```
cd ansible
ansible-inventory --graph      # shows the server found automatically in AWS
ansible-playbook playbook.yml
```
3. Open `http://JENKINS_IP:8080`. Get the first password with:
`ssh -i your-key.pem ubuntu@JENKINS_IP "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"`

### Step 5 - Connect to the Kubernetes cluster
```
aws eks update-kubeconfig --name ivolve-cluster --region us-east-1
kubectl get nodes          # should show 2 nodes
```
Install the nginx ingress controller (needed by `ingress.yaml`):
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.2/deploy/static/provider/aws/deploy.yaml
```

### Step 6 - Edit the placeholders
Replace in the files: `020139096861` (your AWS account number) and `Abdelrahmandaghash` (your GitHub name) inside `k8s/*-deployment.yaml`, `jenkins/*/Jenkinsfile` and `argocd/application.yaml`. Then push to GitHub.

### Step 7 - Jenkins setup (in the Jenkins web page)
1. Install suggested plugins.
2. **Manage Jenkins > Credentials**: add a *Username with password* credential, ID `github-creds` (your GitHub username + a Personal Access Token).
3. **Manage Jenkins > System > Global Trusted Pipeline Libraries**: add a library named `shared-lib`, Git, your repo URL (the `vars/` folder is found automatically).
4. Create three *Pipeline* jobs (`frontend`, `auth`, `roadmap`): "Pipeline script from SCM" -> Git -> your repo -> Script Path `jenkins/frontend/Jenkinsfile`, `jenkins/auth/Jenkinsfile` and `jenkins/roadmap/Jenkinsfile`.
5. Click **Build Now** on each.

### Step 8 - ArgoCD
```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f argocd/application.yaml
```
ArgoCD now watches `k8s/` and deploys it into the `ivolve` namespace. To see the UI:
`kubectl port-forward svc/argocd-server -n argocd 8081:443` then open https://localhost:8081
(user `admin`, password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`).

### Step 9 - Open the app
```
kubectl get ingress -n ivolve
```
Open the address shown in your browser.

### Cleanup (avoid AWS charges!)
```
kubectl delete ingress --all -n ivolve
cd terraform && terraform destroy -var key_name=YOUR_KEY_PAIR_NAME
```

## How the flow works
1. You run the Jenkins pipeline -> it builds the image, scans it with Trivy, pushes it to ECR, deletes it from the server.
2. Jenkins writes the new image name in `k8s/<service>-deployment.yaml` and pushes it to GitHub.
3. ArgoCD sees the change in GitHub and updates the pods in the cluster.
