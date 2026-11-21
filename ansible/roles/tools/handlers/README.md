# 🔄 Tools Role Handlers

> Handlers run only when a task notifies them.

---

## 📁 Project Structure

| File | Purpose |
|------|---------|
| `main.yml` | Handler **Restart Jenkins** — restarts the `jenkins` service after the `jenkins` user is added to the `docker` group |

Because the role notifies this handler at the end of the play, Jenkins picks up its new group
membership in the same run instead of requiring a manual restart.

---

## 🔗 Related

- [tools role](../README.md)
- [tools tasks](../tasks/README.md)
- [roles overview](../../README.md)
