# 🛠️ Ansible Tools Role — Build and Security Tooling

> Installs every command the Jenkins pipelines call: Docker (build/push), AWS CLI (ECR login), Git
> (manifest push) and Trivy (image scan).

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `tasks/main.yml` | 6 tasks: packages, Trivy key, Trivy repo, Trivy package, Docker service, group membership |
| `handlers/main.yml` | `Restart Jenkins` — restarts Jenkins when its `docker` group membership changes |

---

## 🧱 Tasks in Order

1. `apt` → `docker.io`, `git`, `awscli`
2. `get_url` → `https://aquasecurity.github.io/trivy-repo/deb/public.key` to `/usr/share/keyrings/trivy.asc`
3. `apt_repository` → `deb [signed-by=/usr/share/keyrings/trivy.asc] https://aquasecurity.github.io/trivy-repo/deb {{ ansible_distribution_release }} main`
4. `apt` → `trivy`, `update_cache: true`
5. `service` → `docker` started and enabled
6. `user: name=jenkins groups=docker append=true`, `notify: Restart Jenkins`

---

## Inputs / outputs

- **Inputs:** `ansible_distribution_release` fact (used in the Trivy repo line), root privileges.
- **Outputs:** `docker`, `git`, `aws`, `trivy` available to Jenkins; `jenkins` in `docker` group.

---

## 🔗 Used By

| Tool | Pipeline step |
|---|---|
| Docker | `buildImage`, `pushImage`, `deleteImage` |
| Trivy | `scanImage` (`--severity HIGH,CRITICAL`) |
| AWS CLI | `pushImage` (`aws ecr get-login-password`) |
| Git | `pushManifests` |

---

## ✅ Verification

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "docker version --format '{{.Server.Version}}'; trivy --version; aws --version; id jenkins"
```

---

## 🔗 Related

- [roles overview](../README.md)
- [Jenkins shared library](../../../vars/README.md)
