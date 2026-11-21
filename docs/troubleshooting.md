# Troubleshooting

> Practical fixes for the failures you are most likely to see while rebuilding this stack. Commands
> are read-only unless the fix explicitly says to apply/destroy something. For a short summary table,
> see [section 13 of the root README](../README.md#13-troubleshooting).

---

## Contents

- [Docker and Compose](#docker-and-compose)
- [Terraform and AWS](#terraform-and-aws)
- [Ansible and Jenkins host](#ansible-and-jenkins-host)
- [Kubernetes and storage](#kubernetes-and-storage)
- [Jenkins pipelines](#jenkins-pipelines)
- [ArgoCD and GitOps](#argocd-and-gitops)
- [Application](#application)

---

## Docker and Compose

### 1. `docker compose up` fails with `port 80 is already allocated`

**Symptom:** `Error starting userland proxy: listen tcp4 0.0.0.0:80: bind: address already in use`.

**Cause:** `docker-compose.yml` maps host `80` to frontend container `3000`. Another web server is
already using port 80.

**Fix:** stop the other service, or temporarily change the mapping to `"8081:3000"` in your local
copy and open `http://localhost:8081`. Do not commit the change unless you intend to change the
project's public port.

```bash
sudo ss -ltnp | grep ':80 '
docker compose down
```

---

### 2. `auth-service` exits immediately / `/health` returns 503

**Symptom:** Flask logs `Waiting for MySQL (n/30)` or the frontend shows the "MySQL Connection
Error" page from `views/error.ejs`.

**Cause:** one of `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME` is missing (the service
calls `validate_config()` and raises `RuntimeError`), or MySQL is not reachable at service name `db`.

**Fix:** confirm the Compose file supplies all five variables and wait for the health gate:

```bash
docker compose ps
docker compose logs db auth-service
docker compose exec auth-service python -c "import os; print([k for k in ('DB_HOST','DB_PORT','DB_USER','DB_PASSWORD','DB_NAME') if not os.environ.get(k)])"
```

The app retries 30 times with a 2-second gap at startup. If the database is still unavailable after
that window it starts anyway and returns 503 — restart the stack once MySQL is healthy.

---

### 3. MySQL healthcheck never becomes healthy

**Symptom:** `db` shows `starting (unhealthy)` and `auth-service` never starts.

**Cause:** the healthcheck runs `mysqladmin ping -h localhost -p<DB_PASSWORD>` inside the container
(the password comes from `MYSQL_ROOT_PASSWORD`); a corrupted `db-data` volume or an overridden root
password makes it fail.

**Fix:**

```bash
docker compose logs db
# replace <DB_PASSWORD> with the MySQL root password configured in your local Compose setup
docker compose exec db mysqladmin ping -h localhost -p<DB_PASSWORD>
```

If the volume is corrupt, back it up first, then remove it with `docker compose down -v` and let
Compose recreate it. This deletes local data.

---

### 4. Spring Boot image build fails at Maven

**Symptom:** `docker build ./app/roadmap-service` fails during `mvn clean package -DskipTests`.

**Cause:** the Dockerfile expects `target/roadmap-service-1.0.0.jar`, which is produced only if
`pom.xml` coordinates (`com.ivolve:roadmap-service:1.0.0`) and Java 21 are intact.

**Fix:** build locally to see the real Maven error, then rebuild the image:

```bash
cd app/roadmap-service && mvn clean package -DskipTests && cd ../..
docker compose build roadmap-service
```

---

## Terraform and AWS

### 5. `terraform init` cannot access the S3 backend

**Symptom:** `Error loading state: AccessDenied` or `bucket does not exist`.

**Cause:** `terraform/backend.tf` hard-codes bucket `ivolve-terraform-state-020139096861` in
`us-east-1`. Your AWS identity may not have `s3:ListBucket`/`s3:GetObject` on it, or you are in a
different account.

**Fix:** confirm identity and bucket, then create a bucket you own and update `backend.tf`:

```bash
aws sts get-caller-identity
aws s3api head-bucket --bucket ivolve-terraform-state-020139096861
```

---

### 6. `terraform apply` fails at `data.aws_ami.ubuntu`

**Symptom:** `Your query returned no results`.

**Cause:** the AMI filter looks for
`ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*` owned by Canonical (`099720109477`) in
the selected region. That pattern can change or be unavailable in a new region.

**Fix:** verify the data source manually, then update the filter in
`terraform/modules/server/main.tf` if Canonical changed the naming:

```bash
aws ec2 describe-images --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
  --query 'Images[0].[ImageId,Name]' --output table
```

---

### 7. EKS node group never reaches `ACTIVE`

**Symptom:** `kubectl get nodes` returns nothing or nodes stay `NotReady`.

**Cause:** the nodes are placed only in the two private subnets and reach the internet through the
single NAT Gateway. A missing NAT route, missing `AmazonEKSWorkerNodePolicy` attachment, or an EIP
quota problem prevents bootstrap.

**Fix:**

```bash
aws eks describe-node-group --cluster-name ivolve-cluster --node-group ivolve-nodes \
  --query 'nodegroup.{status:status,subnets:subnets,instanceTypes:instanceTypes}'
terraform -chdir=terraform output
kubectl get nodes -o wide
```

Check that `private-rt` has a `0.0.0.0/0` route to `ivolve-nat`.

---

### 8. EBS PVC stays `Pending`

**Symptom:** `kubectl get pvc -n ivolve` shows `data-mysql-0` as `Pending`.

**Cause:** the `ebs-sc` StorageClass uses provisioner `ebs.csi.aws.com` with
`WaitForFirstConsumer`. If the `aws-ebs-csi-driver` add-on is missing or its IRSA role trust is
wrong, no volume can be created.

**Fix:**

```bash
kubectl get pods -n kube-system | grep ebs-csi
kubectl describe storageclass ebs-sc
kubectl describe pvc data-mysql-0 -n ivolve
terraform -chdir=terraform state show module.eks.aws_eks_addon.ebs_csi
```

The IRSA role must trust `system:serviceaccount:kube-system:ebs-csi-controller-sa` and have
`AmazonEBSCSIDriverPolicy`.

---

### 9. `terraform destroy` leaves the Load Balancer behind

**Symptom:** an ELB and its security group remain after destroy; cost continues.

**Cause:** the Kubernetes Ingress creates the AWS Load Balancer outside Terraform's state. Terraform
does not know about it.

**Fix:** delete the Ingress first and wait for the ELB to disappear, then destroy:

```bash
kubectl delete ingress --all -n ivolve
terraform -chdir=terraform destroy -var key_name=<KEY_PAIR>
```

---

## Ansible and Jenkins host

### 10. Ansible cannot find the Jenkins host

**Symptom:** `ansible-inventory --graph` shows no hosts; playbook reports `Skipped: 1`.

**Cause:** `ansible/aws_ec2.yml` filters on `tag:Name=jenkins-server` and
`instance-state-name=running`. Terraform sets that tag, but the instance may have been stopped or
the credentials/region are wrong.

**Fix:**

```bash
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=jenkins-server" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' --output table
ansible-inventory --graph
```

---

### 11. Ansible SSH fails with `Permission denied (publickey)`

**Symptom:** `FAILED! => "Permission denied (publickey)"`.

**Cause:** `ansible/ansible.cfg` sets `private_key_file = /home/3bdel/ivolve-key.pem`, which does not
match your key path or key pair name.

**Fix:** set the path to your own PEM file and restrict its permissions:

```bash
chmod 400 ~/ivolve-key.pem
# edit ansible/ansible.cfg: private_key_file = /home/<you>/ivolve-key.pem
ansible all -m ping
```

`remote_user = ubuntu` must also match the Ubuntu AMI used by Terraform.

---

### 12. Jenkins apt install fails with `NO_PUBKEY 7198F4B714ABFC68`

**Symptom:** `apt update` inside the `jenkins` role fails because the 2023 signing key expired on
2026-03-26.

**Cause:** outdated Jenkins key. The role already downloads `jenkins.io-2026.key` to
`/usr/share/keyrings/jenkins-keyring.asc` and uses `signed-by=`.

**Fix:** re-run the playbook. If the error persists, verify the repository line:

```bash
cat /etc/apt/sources.list.d/jenkins.list
sudo apt-key del 7198F4B714ABFC68 2>/dev/null || true
cd ansible && ansible-playbook playbook.yml
```

---

### 13. Jenkins service is inactive with `StartLimitBurst`

**Symptom:** `systemctl status jenkins` shows `Failed: Result: start-limit-hit`.

**Cause:** repeated failed starts latch systemd's rate limit. The `jenkins` role already runs
`systemctl reset-failed jenkins` before starting the service.

**Fix:**

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "sudo systemctl reset-failed jenkins && sudo systemctl restart jenkins && sudo systemctl is-active jenkins"
```

If Java is too old, the log says `older than the minimum required version (Java 21)`; re-run the
`java` role (`openjdk-21-jre`).

---

## Kubernetes and storage

### 14. Pods are `Pending` with `FailedScheduling`

**Symptom:** `kubectl describe pod -n ivolve` shows insufficient CPU or no nodes.

**Cause:** the fixed node group has 2 × `t3.small` and no autoscaling. Four workloads plus ArgoCD
and ingress-nginx can exhaust it, especially with more replicas.

**Fix:**

```bash
kubectl describe nodes | grep -A5 'Allocated resources'
kubectl get pods -A --field-selector=status.phase=Pending
```

Reduce replicas, or (deliberately) raise the node group size in `terraform/modules/eks/main.tf`
and apply the change. This increases cost.

---

### 15. `auth` pod crashes with missing DB variables

**Symptom:** `kubectl logs deploy/auth -n ivolve` shows
`Missing database environment variables: ...`.

**Cause:** the Deployment expects ConfigMap `app-config` and Secret `app-secret` in the same
namespace. If ArgoCD synced Deployments before the ConfigMap/Secret existed, the container starts
with an incomplete environment.

**Fix:**

```bash
kubectl get configmap,secret -n ivolve
kubectl describe pod -n ivolve -l app=auth
kubectl rollout restart deployment/auth -n ivolve
```

---

### 16. MySQL pod fails with `lost+found` error

**Symptom:** MySQL refuses to initialise `/var/lib/mysql` because the EBS volume contains
`lost+found`.

**Cause:** mounting a raw EBS filesystem directly at the MySQL data directory.

**Fix:** already handled in `k8s/mysql-statefulset.yaml` with `subPath: mysql`. If you removed it,
restore the `subPath` line and recreate the pod. Do not delete the PVC unless you want to lose the
database.

---

### 17. Ingress has no address

**Symptom:** `kubectl get ingress -n ivolve` shows an empty `ADDRESS` column.

**Cause:** the ingress-nginx controller manifest was not applied, or the AWS Load Balancer could not
be created (subnet tags / IAM permissions).

**Fix:**

```bash
kubectl get pods -n ingress-nginx
kubectl describe ingress frontend-ingress -n ivolve
kubectl get events -n ivolve --sort-by=.lastTimestamp | tail -20
```

Reapply the controller manifest from Step 6 of the root README if the namespace is missing. The public
subnets already carry `kubernetes.io/role/elb = 1`.

---

## Jenkins pipelines

### 18. `docker: command not found` inside a pipeline

**Symptom:** the Build Image stage fails immediately.

**Cause:** the Ansible `tools` role did not add `jenkins` to the `docker` group, or the handler
`Restart Jenkins` did not run.

**Fix:**

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "id jenkins && sudo systemctl restart jenkins && sudo -u jenkins docker version"
```

---

### 19. ECR login or push is denied

**Symptom:** `denied: Your authorization token has expired` or `no basic auth credentials`.

**Cause:** the Jenkins EC2 instance profile lacks `AmazonEC2ContainerRegistryPowerUser`, or the
`REGISTRY` value in the Jenkinsfile still contains the wrong account ID.

**Fix:**

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "aws sts get-caller-identity && aws ecr describe-repositories --region us-east-1"
```

Confirm that `jenkins/frontend/Jenkinsfile`, `jenkins/auth/Jenkinsfile` and
`jenkins/roadmap/Jenkinsfile` point at the same account as `terraform/backend.tf`.

---

### 20. `git push` in Push Manifests fails authentication

**Symptom:** `Authentication failed` or `remote: Invalid username or password`.

**Cause:** the Jenkins credential with ID **`github-creds`** is missing, or the PAT no longer has
`repo` scope.

**Fix:** in Jenkins → Manage Jenkins → Credentials, add *Username with password* with exactly the
ID `github-creds`, username = your GitHub user, password = a PAT with `repo` scope. Then re-run the
job. `vars/pushManifests.groovy` reads that ID; it will not work with a different one.

---

### 21. Trivy finds vulnerabilities but the build continues

**Symptom:** the Scan Image stage prints findings and the pipeline still goes green.

**Cause:** `vars/scanImage.groovy` runs `trivy image --severity HIGH,CRITICAL <image>` without
`--exit-code 1`. It reports, but does not gate.

**Fix:** this is a deliberate design choice in this repository, not a failure. If you want a hard
gate, add `--exit-code 1` in `vars/scanImage.groovy` and accept that vulnerable images will stop the
deployment. Record the change in your report.

---

## ArgoCD and GitOps

### 22. `ivolve-app` shows `OutOfSync` forever

**Symptom:** the ArgoCD UI never reaches `Synced`.

**Cause:** the manifest pushed by Jenkins differs from the live cluster state, or the Application's
source path/branch is wrong.

**Fix:**

```bash
kubectl get application ivolve-app -n argocd -o yaml | grep -A8 'source:'
kubectl describe application ivolve-app -n argocd | tail -30
```

Verify `source.path: k8s`, `source.targetRevision: main`, and that the repository URL matches the one
in `argocd/application.yaml`. Press **Refresh** in the UI to force a re-poll.

---

### 23. ArgoCD UI is unreachable through port-forward

**Symptom:** `https://localhost:8081` refuses connections.

**Cause:** the port-forward targets `svc/argocd-server` port `443`, which only exists after the
ArgoCD install manifest has created the Service.

**Fix:**

```bash
kubectl get svc -n argocd
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

In a second terminal:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Do not paste that password into documentation or tickets.

---

## Application

### 24. Login page loads but roadmap page shows "Application Error"

**Symptom:** login succeeds, `/roadmap` renders `views/error.ejs` with "The roadmap service is
unavailable."

**Cause:** the frontend calls `ROADMAP_SERVICE_URL` (`http://roadmap:8080`) and that service or its
ClusterIP Service is missing/unready.

**Fix:**

```bash
kubectl get pods,svc -n ivolve
kubectl logs deploy/frontend -n ivolve
kubectl logs deploy/roadmap -n ivolve
curl -s http://<INGRESS_ADDRESS>/api/roadmap -o /dev/null -w '%{http_code}\n'
```

Note that the frontend exposes only its own UI routes; the API paths are reached server-side through
the two internal Service names.

---

### 25. Session resets on every request

**Symptom:** after login, refreshing `/roadmap` redirects back to `/`.

**Cause:** `SESSION_SECRET` is not injected by `k8s/frontend-deployment.yaml`, so `server.js` uses
its fallback `change-me-in-k8s`. If pods are recreated with a different secret or multiple replicas
are added, sessions become invalid. With one replica and the default, this is usually a cookie
issue (browser blocking httpOnly cookies).

**Fix:** check browser cookie settings first. For a durable fix, add `SESSION_SECRET` to
`app-secret` and include `secretRef: app-secret` in the frontend Deployment — see
[Security considerations](../README.md#11-security-considerations).
