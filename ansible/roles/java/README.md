# ☕ Ansible Java Role — Java Runtime

> Installs the runtime required by Jenkins. A code comment records why: Jenkins packages built after
> Oct 2026 require Java 21 (older versions fail with "older than the minimum required version
> (Java 21)").

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `tasks/main.yml` | `apt: name=openjdk-21-jre state=present update_cache=true` |

---

## ✅ Inputs and Outputs

- **Input:** `become: true` from the playbook (apt needs root).
- **Output:** `openjdk-21-jre` present; `java -version` reports 21.

---

## ✅ Verification

```bash
ssh -i ~/ivolve-key.pem ubuntu@<JENKINS_PUBLIC_IP> "java -version"
```

---

## 🔗 Related

- [roles overview](../README.md)
- [jenkins role](../jenkins/README.md)
