# 📝 Java Role Tasks

> The single task list for the `java` role.

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `main.yml` | Installs `openjdk-21-jre` with `update_cache: yes` — Jenkins requires Java 21 or newer |

Ansible loads `main.yml` automatically when the role is included by `playbook.yml`; no other task
files are needed.

---

## 🔗 Related

- [java role](../README.md)
- [roles overview](../../README.md)
