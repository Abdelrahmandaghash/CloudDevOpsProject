# `ansible/roles/jenkins` — Jenkins installation

> Adds the official Jenkins apt repository with the current signing key, installs Jenkins, clears any
> latched systemd start-limit state, and makes sure the service is running and enabled at boot.

## Contents

| File | Purpose |
|------|---------|
| `tasks/main.yml` | GPG key download, apt repository, package install, systemd reset, service start/enable |

## Tasks in order

1. Download `https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key` to
   `/usr/share/keyrings/jenkins-keyring.asc` with `force: true`.
2. Add `deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/`
   to `/etc/apt/sources.list.d/jenkins.list`.
3. Install the `jenkins` package.
4. Run `systemctl reset-failed jenkins` (`changed_when: false`) to clear systemd's
   `StartLimitBurst=5 / 5m` latch before the first start.
5. Ensure service `jenkins` is **started** and **enabled**.

The key download uses `force: true` so re-running the playbook always refreshes the signing key.

## Result

Jenkins listens on port **8080**; the initial admin password is at
`/var/lib/jenkins/secrets/initialAdminPassword` on the server.

## Related

- [roles overview](../README.md)
- [java role](../java/README.md) — installed first
- [tools role](../tools/README.md) — adds Docker access for the `jenkins` user
