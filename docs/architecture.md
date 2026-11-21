# Architecture deep dive

> Companion to the [root README](../README.md). This document explains **how the pieces fit
> together and why each one was chosen**, using only names and values that exist in this repository.

---

## Contents

- [1. System context](#1-system-context)
- [2. AWS network](#2-aws-network)
- [3. CI/CD sequence](#3-cicd-sequence)
- [4. Kubernetes workload layout](#4-kubernetes-workload-layout)
- [5. Component rationale](#5-component-rationale)
- [6. Data and identity flow](#6-data-and-identity-flow)
- [7. Failure domains](#7-failure-domains)
- [8. Related evidence](#8-related-evidence)

---

## 1. System context

```mermaid
flowchart LR
    DEV[Developer / git push] --> GH[(GitHub repository<br/>Abdelrahmandaghash/CloudDevOpsProject)]

    GH -->|Pipeline script from SCM| JEN[Jenkins on EC2<br/>t3.small / port 8080]
    GH -->|Shared library shared-lib| JEN
    GH -->|GitOps source path k8s/| ARC[ArgoCD Application<br/>ivolve-app]

    JEN -->|1 build → 2 scan → 3 push| ECR[(Amazon ECR<br/>frontend / auth / roadmap)]
    JEN -->|5 sed image tag + 6 git push| GH

    ARC -->|automated sync:<br/>prune + selfHeal| EKS[Amazon EKS cluster<br/>ivolve-cluster]

    ECR -->|nodes pull images| EKS
    EKS --> LB[ingress-nginx<br/>AWS Load Balancer]
    LB --> USER[Browser]
```

**Reading the diagram**

1. GitHub is the only place where two things are stored: the application source **and** the desired
   Kubernetes state (`k8s/`).
2. Jenkins reads both the pipeline definitions (`jenkins/*/Jenkinsfile`) and the reusable steps
   (`vars/`). It never talks to the EKS API.
3. ArgoCD reads `k8s/` from GitHub and is the only component that applies manifests to EKS.
4. ECR is the hand-off between CI and CD: Jenkins writes images, EKS nodes read them.

![End-to-end pipeline overview](images/07-jenkins-jobs-all-green.png)

---

## 2. AWS network

Terraform builds one VPC, two public and two private subnets in the **first two available AZs**, one
Internet Gateway, one NAT Gateway, a NACL applied to all four subnets, a Jenkins EC2 in a public
subnet, and an EKS cluster whose two `t3.small` nodes live in the private subnets.

```mermaid
flowchart TB
    subgraph REGION["Region us-east-1"]
      IGW[Internet Gateway<br/>ivolve-igw]

      subgraph VPC["VPC 10.0.0.0/16 — ivolve-vpc (DNS hostnames on)"]
        NACL[Network ACL ivolve-nacl<br/>ingress 100 allow all<br/>egress 100 allow all<br/>applied to all 4 subnets]

        subgraph AZ1["Availability zone A — first AZ from data.aws_availability_zones"]
          direction TB
          PUB1["Public subnet 10.0.1.0/24<br/>public-subnet-1<br/>map_public_ip_on_launch = true<br/>tag kubernetes.io/role/elb = 1"]
          PRIV1["Private subnet 10.0.3.0/24<br/>private-subnet-1<br/>tag kubernetes.io/role/internal-elb = 1"]
          JEN[EC2 jenkins-server<br/>t3.small / 20 GB<br/>sg jenkins-sg: 22, 8080<br/>profile jenkins-profile]
          NODE1[EKS node 1<br/>t3.small]
          NAT[NAT Gateway ivolve-nat<br/>EIP in public-subnet-1]
          PUB1 --- JEN
          PUB1 --- NAT
          PRIV1 --- NODE1
        end

        subgraph AZ2["Availability zone B — second AZ"]
          direction TB
          PUB2["Public subnet 10.0.2.0/24<br/>public-subnet-2<br/>tag kubernetes.io/role/elb = 1"]
          PRIV2["Private subnet 10.0.4.0/24<br/>private-subnet-2<br/>tag kubernetes.io/role/internal-elb = 1"]
          NODE2[EKS node 2<br/>t3.small]
          PRIV2 --- NODE2
        end

        PUBRT[Route table public-rt<br/>0.0.0.0/0 → IGW]
        PRIVRT[Route table private-rt<br/>0.0.0.0/0 → NAT]
        PUBRT --> PUB1
        PUBRT --> PUB2
        PRIVRT --> PRIV1
        PRIVRT --> PRIV2
      end

      EKSCTL[EKS control plane<br/>ivolve-cluster]
      ECR[(ECR repositories<br/>frontend / auth / roadmap)]
      S3[(S3 backend<br/>terraform state)]
      OIDC[OIDC provider + IRSA<br/>ebs-csi-controller-role]
    end

    IGW <--> PUBRT
    NAT --> IGW
    EKSCTL --- NODE1
    EKSCTL --- NODE2
    EKSCTL --- OIDC
    OIDC --> EBS[aws-ebs-csi-driver add-on]
    EBS --> PRIV1
    JEN -->|AmazonEC2ContainerRegistryPowerUser| ECR
    NODE1 -->|ReadOnly pull| ECR
    NODE2 -->|ReadOnly pull| ECR
    TERRAFORM[terraform CLI] -->|state| S3
```

### Routing rules

| Subnet type | Route table | Destination | Target | Reason |
|---|---|---|---|---|
| Public (×2) | `public-rt` | `0.0.0.0/0` | `ivolve-igw` | Jenkins needs inbound SSH/8080 and outbound package downloads |
| Private (×2) | `private-rt` | `0.0.0.0/0` | `ivolve-nat` | EKS nodes pull images and reach AWS APIs without being internet-addressable |

### Security group — `jenkins-sg`

| Direction | Rule | Protocol | Port | Source / destination | Purpose |
|---|---|---|---|---|---|
| Ingress | 1 | tcp | 22 | `0.0.0.0/0` | SSH for Ansible and administration |
| Ingress | 2 | tcp | 8080 | `0.0.0.0/0` | Jenkins web UI |
| Egress | 1 | all | all | `0.0.0.0/0` | apt, Docker Hub/ECR, AWS APIs |

### Network ACL — `ivolve-nacl`

| Direction | Rule number | Protocol | Port | CIDR | Action |
|---|---:|---|---|---|---|
| Ingress | 100 | `-1` (all) | 0–65535 | `0.0.0.0/0` | allow |
| Egress | 100 | `-1` (all) | 0–65535 | `0.0.0.0/0` | allow |

> The NACL is deliberately permissive; the declarative filtering is done by `jenkins-sg`. See the
> [Security considerations](../README.md#11-security-considerations) section for the recommended
> hardening.

![ECR repositories](images/03-ecr-repositories.png)
![Nodes ready](images/04-eks-nodes-ready.png)

---

## 3. CI/CD sequence

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant GH as GitHub main
    participant J as Jenkins (EC2)
    participant E as Amazon ECR
    participant A as ArgoCD ivolve-app
    participant K as EKS ivolve namespace

    Dev->>GH: git push (source or manifests)
    Note over J: User clicks Build Now on frontend / auth / roadmap
    GH-->>J: Pipeline script from SCM + shared-lib vars/
    J->>J: Build Image — docker build -t IMAGE FOLDER
    J->>J: Scan Image — trivy image --severity HIGH,CRITICAL IMAGE
    J->>E: Push Image — aws ecr get-login-password + docker push
    E-->>J: image stored at REGISTRY/service:BUILD_NUMBER
    J->>J: Delete Image Locally — docker rmi IMAGE
    J->>J: Update Manifests — sed image: line in k8s/<service>-deployment.yaml
    J->>GH: Push Manifests — git add k8s, commit, push HEAD:main (github-creds)
    GH-->>A: new commit on main, path k8s/
    A->>K: automated sync (prune + selfHeal)
    K->>E: kubelet pulls REGISTRY/service:BUILD_NUMBER
    K-->>A: Healthy / Synced
    K-->>Dev: new version served through frontend-ingress
```

**Why the manifest push is the boundary:** Jenkins does not need a kubeconfig. Its last action is an
ordinary Git commit. ArgoCD polls that Git path and performs the deployment. This is the defining
property of the GitOps design in this project.

![Jenkins jobs green](images/07-jenkins-jobs-all-green.png)
![ArgoCD healthy](images/14-argocd-application-healthy.png)

---

## 4. Kubernetes workload layout

```mermaid
flowchart TB
    subgraph CLUSTER["EKS cluster ivolve-cluster"]
      subgraph NG["Namespace ivolve"]
        ING["Ingress frontend-ingress<br/>ingressClassName nginx<br/>path / → frontend:3000"]

        subgraph APPS["Application services (ClusterIP)"]
          FSVC[Service frontend<br/>port 3000 → 3000]
          ASVC[Service auth<br/>port 5000 → 5000]
          RSVC[Service roadmap<br/>port 8080 → 8080]
        end

        FDEP[Deployment frontend<br/>replicas 1<br/>ECR frontend image]
        ADEP[Deployment auth<br/>replicas 1<br/>ECR auth image]
        RDEP[Deployment roadmap<br/>replicas 1<br/>ECR roadmap image]

        HLS[Headless Service mysql<br/>clusterIP None<br/>stable DNS mysql-0.mysql]
        STS[StatefulSet mysql<br/>replicas 1<br/>image mysql:8]

        PVC[PVC data-mysql-0<br/>1Gi ReadWriteOnce]
        SC[StorageClass ebs-sc<br/>ebs.csi.aws.com<br/>WaitForFirstConsumer]
        CM[ConfigMap app-config<br/>DB_HOST / DB_PORT / DB_NAME / DB_USER<br/>AUTH_SERVICE_URL / ROADMAP_SERVICE_URL]
        SEC[Secret app-secret<br/>DB_PASSWORD / MYSQL_ROOT_PASSWORD]
      end

      CTRL[ingress-nginx controller<br/>namespace ingress-nginx]
    end

    ING --> FSVC
    FSVC --> FDEP
    FDEP -->|AUTH_SERVICE_URL| ASVC
    FDEP -->|ROADMAP_SERVICE_URL| RSVC
    ASVC --> ADEP
    RSVC --> RDEP
    ADEP -->|DB_HOST=mysql-0.mysql| HLS
    HLS --> STS
    STS --> PVC
    PVC --> SC
    CM -.envFrom.-> FDEP
    CM -.envFrom.-> ADEP
    CM -.configMapKeyRef DB_NAME.-> STS
    SEC -.envFrom.-> ADEP
    SEC -.envFrom.-> STS
    CTRL --> ING
```

### Request path

1. The browser reaches the AWS Load Balancer created for `frontend-ingress`.
2. ingress-nginx matches path `/` and forwards to `frontend:3000`.
3. `/login` and `/signup` in the frontend call `http://auth:5000/api/auth/...`.
4. `/roadmap` in the frontend calls `http://roadmap:8080/api/roadmap`.
5. The auth service writes to `mysql-0.mysql:3306`; MySQL data lives on a 1 Gi EBS volume.
6. The session cookie is signed by `SESSION_SECRET`. The Deployment does not inject that variable,
   so the application uses its built-in default — see
   [Security considerations](../README.md#11-security-considerations).

![Ingress and login](images/15-app-login-page.png)
![Roadmap page](images/16-app-roadmap-page.png)

---

## 5. Component rationale

| Component | What it does here | Why it was chosen |
|---|---|---|
| Docker + Dockerfiles | Packages each microservice into an immutable image | One artifact for local Compose runs and for EKS; the Java service is multi-stage so Maven never ships in the runtime image |
| Docker Compose | Runs `db`, `auth-service`, `roadmap-service`, `frontend` locally | Health-gated startup (`db` healthy before `auth-service`) reproduces the cluster's dependency order without Kubernetes |
| Terraform (S3 backend) | Creates 36 AWS resources and keeps state in S3 | One command creates/recreates the whole environment; S3 state can be shared and versioned |
| Modules `network`, `server`, `eks`, `ecr` | Split the infrastructure into composable units | Each unit has clear inputs/outputs, which makes `main.tf` read like a blueprint |
| EKS managed node group | Runs the four workloads on 2 × `t3.small` | Managed control plane; fixed size (`min = max = desired = 2`) keeps cost predictable |
| IRSA + EBS CSI add-on | Lets the CSI controller create EBS volumes without node credentials | Pods cannot use the node IAM role; IRSA is the AWS-native way to grant a service account permissions |
| Ansible dynamic inventory | Finds the EC2 by tag `Name=jenkins-server` | The public IP changes after every `apply`; a static inventory would go stale |
| Ansible roles `java`, `jenkins`, `tools` | Configure the CI host declaratively | Idempotent, readable, and reusable; the Jenkins role also clears systemd's failed-start latch |
| Jenkins + shared library | Six identical stages for each of the three services | `vars/` keeps the logic in one place; the image tag is `BUILD_NUMBER`, so every deployment maps to a build |
| Trivy | Reports HIGH/CRITICAL findings before push | Shifts vulnerability discovery left in the pipeline |
| ECR | Private registry for the three images | Native IAM integration with both the Jenkins instance role and the EKS node role |
| ArgoCD `Application` | Watches `k8s/` on `main` and syncs with `prune` + `selfHeal` | Git becomes the audit trail; drift is corrected automatically and Jenkins needs no cluster credentials |
| ingress-nginx | Exposes the frontend through one AWS Load Balancer | A single public entry point for the whole application |
| StatefulSet + headless Service | Gives MySQL a stable name (`mysql-0.mysql`) and disk | Database identity and storage must survive pod restarts |

---

## 6. Data and identity flow

| Flow | Mechanism | Source of the value |
|---|---|---|
| Terraform state | S3 backend `ivolve-terraform-state-020139096861`, key `cloud-devops-project/terraform.tfstate` | `terraform/backend.tf` |
| Ansible finds Jenkins | `amazon.aws.aws_ec2` plugin, filter `tag:Name=jenkins-server`, `instance-state-name=running` | `ansible/aws_ec2.yml` |
| Ansible SSH key | `private_key_file = /home/3bdel/ivolve-key.pem` | `ansible/ansible.cfg` (change to your own path) |
| Jenkins pushes to ECR | Instance profile `jenkins-profile` → `jenkins-role` → `AmazonEC2ContainerRegistryPowerUser` | `terraform/modules/server/main.tf` |
| EKS nodes pull from ECR | Node role policies including `AmazonEC2ContainerRegistryReadOnly` | `terraform/modules/eks/main.tf` |
| EBS CSI creates disks | OIDC provider → IRSA role `ebs-csi-controller-role` → SA `kube-system/ebs-csi-controller-sa` | `terraform/modules/eks/main.tf` |
| Jenkins pushes manifests | Credential `github-creds` (username + PAT with `repo` scope) | `vars/pushManifests.groovy` |
| Pods get configuration | `envFrom` ConfigMap `app-config` and Secret `app-secret` | `k8s/*-deployment.yaml`, `k8s/mysql-statefulset.yaml` |
| Users log in | Frontend → auth → bcrypt hash in MySQL `users` table | `app/auth-service/app.py` |

---

## 7. Failure domains

| If this fails… | Effect | Recovery |
|---|---|---|
| NAT Gateway | EKS nodes cannot pull new images or reach AWS APIs | Recreate the NAT EIP/Gateway via Terraform; existing pods keep running |
| Jenkins EC2 | No new builds or manifest updates | Re-run Terraform to replace the instance, then re-run Ansible; dynamic inventory finds the new IP |
| ECR | New deployments cannot pull images; already-cached images may still run | Recreate repositories via Terraform and re-run all three pipelines |
| EBS CSI add-on / IRSA | MySQL PVC stays `Pending` | Verify the add-on and the IRSA trust policy; recreate via Terraform |
| ArgoCD | Manual changes are no longer reverted; new image tags are not deployed | Restore the `ivolve-app` Application; it will reconcile `k8s/` on the next sync |
| ingress-nginx controller | Ingress address stops serving | Reapply the controller manifest from the root README's Step 6 |

---

## 8. Related evidence

- [Screenshot gallery index](../Screenshots/README.md)
- [Screenshot capture manifest](images/README.md)
- [Step-by-step build guide](../README.md#step-by-step-deployment-guide)
- [Troubleshooting](troubleshooting.md)
