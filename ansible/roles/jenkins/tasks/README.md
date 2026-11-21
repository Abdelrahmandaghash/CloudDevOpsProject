# `roles/jenkins/tasks/` — Jenkins installation tasks

> Ordered task list for the `jenkins` role: signing key → apt repository → package → systemd → service.

## Contents

| File | Purpose |
|------|---------|
| `main.yml` | Downloads `jenkins.io-2026.key` (force refresh), adds the Debian repo, installs `jenkins`, runs `systemctl reset-failed jenkins`, then starts and enables the service |

The key is stored at `/usr/share/keyrings/jenkins-keyring.asc` and referenced by the repository line
with `signed-by=`. The reset step clears systemd's failed-start rate limit before the first launch.

## Related

- [jenkins role](../README.md)
- [roles overview](../../README.md)
