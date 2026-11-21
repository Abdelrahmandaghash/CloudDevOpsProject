# `ansible/roles/` — configuration roles

> Three roles applied in order by [`playbook.yml`](../playbook.yml).

| Order | Role | Responsibility | Key tasks / output |
|---:|---|---|---|
| 1 | [java/](java/README.md) | Java runtime | Installs `openjdk-21-jre` — required by current Jenkins packages |
| 2 | [jenkins/](jenkins/README.md) | Jenkins installation | 2026 signing key, apt repo, package, `systemctl reset-failed`, start + enable; UI on 8080 |
| 3 | [tools/](tools/README.md) | Build & security tooling | `docker.io`, `git`, `awscli`, Trivy repo + package, Docker service, `jenkins` in `docker` group |

Each role follows standard Ansible layout with `tasks/main.yml`; `tools` also has
`handlers/main.yml` to restart Jenkins after its group membership changes.

## Inputs / outputs

- **Inputs:** the discovered host from `aws_ec2.yml`, `become: true`, and the SSH key in `ansible.cfg`.
- **Outputs:** Java 21 installed, Jenkins service active and enabled, Docker active and enabled,
  Trivy and AWS CLI available to the `jenkins` user.

## How to run

```bash
cd ..
ansible-playbook --syntax-check -i 'localhost,' playbook.yml
ansible-playbook playbook.yml
```

## Related

- [Ansible overview](../README.md)
- [Root deployment guide](../../README.md)
