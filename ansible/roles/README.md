# `ansible/roles/` — configuration roles

> Three focused roles applied in order by [`playbook.yml`](../playbook.yml).

| Order | Role | Responsibility |
|-------|------|----------------|
| 1 | [java/](java/README.md) | Install Java 21 (required by current Jenkins packages) |
| 2 | [jenkins/](jenkins/README.md) | Add the Jenkins apt repo with its current signing key, install, reset systemd state, start & enable |
| 3 | [tools/](tools/README.md) | Install Docker, Git, AWS CLI and Trivy; start Docker; grant Jenkins Docker access |

Each role follows standard Ansible layout with a `tasks/main.yml`; `tools` also has a
`handlers/main.yml` used to restart Jenkins after its group membership changes.

## Applying them

```bash
cd ..
ansible-playbook playbook.yml --tags java      # individual role if tagged
ansible-playbook playbook.yml                  # all three, in order
```

## Related

- [Ansible overview](../README.md)
- [Root deployment guide](../../README.md)
