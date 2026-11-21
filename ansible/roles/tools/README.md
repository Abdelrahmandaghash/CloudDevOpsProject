# `ansible/roles/tools` — build & security tooling

> Installs everything the Jenkins pipelines need at runtime: Docker to build images, the AWS CLI to
> log in to ECR, Git to push manifests, and Trivy to scan images.

## Contents

| File | Purpose |
|------|---------|
| `tasks/main.yml` | Package installs, Trivy apt repo, Docker service, group membership |
| `handlers/main.yml` | `Restart Jenkins` handler — restarts Jenkins when its Docker group membership changes |

## Tasks in order

1. Install `docker.io`, `git`, `awscli` via apt.
2. Download the Trivy signing key from `https://aquasecurity.github.io/trivy-repo/deb/public.key`
   to `/usr/share/keyrings/trivy.asc`.
3. Add the Trivy apt repository, using `{{ ansible_distribution_release }}` for the suite name.
4. Install `trivy` with `update_cache: yes`.
5. Start and enable the `docker` service.
6. Add user `jenkins` to group `docker` (`append: true`), notifying **Restart Jenkins**.

The group membership lets the Jenkins process run `docker build` without sudo; the handler restart
makes the new group take effect in the same playbook run.

## Used by

| Tool | Pipeline step |
|------|---------------|
| Docker | `buildImage.groovy`, `pushImage.groovy`, `deleteImage.groovy` |
| Trivy | `scanImage.groovy` (`--severity HIGH,CRITICAL`) |
| AWS CLI | `pushImage.groovy` (`aws ecr get-login-password`) |
| Git | `pushManifests.groovy` |

## Related

- [roles overview](../README.md)
- [Jenkins shared library](../../../vars/README.md)
