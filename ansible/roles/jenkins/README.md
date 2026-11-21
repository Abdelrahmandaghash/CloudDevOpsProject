# 🔧 Ansible Jenkins Role — Jenkins Installation

> Adds the official Jenkins apt repository with the **2026** signing key, installs Jenkins, clears any
> latched systemd start-limit state, then starts and enables the service.

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `tasks/main.yml` | 5 ordered tasks (see below) |

---

## 🧱 Tasks in Order

1. `get_url` → `https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key` to
   `/usr/share/keyrings/jenkins-keyring.asc` with `force: true`. The comment explains the 2023 key
   expired 2026-03-26 and caused `NO_PUBKEY 7198F4B714ABFC68`.
2. `apt_repository` → `deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/`
3. `apt` → package `jenkins`, `update_cache: true`
4. `command: systemctl reset-failed jenkins`, `changed_when: false` — clears `StartLimitBurst=5 / 5m`
5. `service: name=jenkins state=started enabled=true`

---

## Inputs / outputs

- **Inputs:** Java 21 from the `java` role; root privileges from the playbook.
- **Outputs:** Jenkins listening on **8080**, enabled at boot, initial admin password at
  `/var/lib/jenkins/secrets/initialAdminPassword`.

---

## ✅ Verification

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> \
  "systemctl is-active jenkins; sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
curl -I http://<JENKINS_PUBLIC_IP>:8080
```

> The exact Jenkins package version is not pinned in this repository — it is whatever
> `pkg.jenkins.io/debian-stable` serves at install time. `TODO: record the installed Jenkins version
> in your project report (evidence capture shows 2.580.2).`

---

## 🔗 Related

- [roles overview](../README.md)
- [java role](../java/README.md)
- [tools role](../tools/README.md)
