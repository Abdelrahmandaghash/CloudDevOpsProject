# 📝 Tools Role Tasks

> Installs and configures every command the Jenkins pipelines use.

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `main.yml` | Installs `docker.io`, `git`, `awscli`; adds the Trivy apt key/repo and installs `trivy`; starts and enables Docker; adds `jenkins` to the `docker` group (notifies the restart handler) |

---

## 🔗 Related

- [tools role](../README.md)
- [restart handler](../handlers/README.md)
- [roles overview](../../README.md)
