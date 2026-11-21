# `vars/` — Jenkins shared library

> Reusable pipeline steps shared by all three Jenkinsfiles. Register this folder as a global
> pipeline library named **`shared-lib`** in Jenkins; each file name becomes a callable function.

## Functions

| File / function | Signature | What it does |
|-----------------|-----------|--------------|
| `buildImage.groovy` | `buildImage(image, folder)` | `docker build -t <image> <folder>` |
| `scanImage.groovy` | `scanImage(image)` | `trivy image --severity HIGH,CRITICAL <image>` |
| `pushImage.groovy` | `pushImage(image, registry, region)` | `aws ecr get-login-password … \| docker login …`, then `docker push <image>` |
| `deleteImage.groovy` | `deleteImage(image)` | `docker rmi <image>` to free disk space on the CI host |
| `updateManifests.groovy` | `updateManifests(file, image)` | `sed -i 's\|image: .*\|image: <image>\|' <file>` |
| `pushManifests.groovy` | `pushManifests(githubRepo)` | Commits `k8s/` and pushes to `main` using the `github-creds` credential |

## Authentication

`pushManifests.groovy` wraps a `withCredentials([usernamePassword(...)])` block:

- credential ID: **`github-creds`** (must match exactly),
- username variable `GIT_USER`, password variable `GIT_TOKEN` (a GitHub PAT with `repo` scope),
- commit identity: `jenkins / jenkins@ivolve.com`,
- commit message: `Update image from Jenkins build ${env.BUILD_NUMBER}`,
- push target: `https://${GIT_USER}:${GIT_TOKEN}@<repo> HEAD:main`.

That push is the hand-off to ArgoCD: it sees a new manifest on `main` and syncs the cluster.

## Tools assumed on the Jenkins host

Docker, Trivy and the AWS CLI — all installed by the [Ansible `tools` role](../ansible/roles/tools/README.md).

## Related

- [Jenkins pipelines](../jenkins/README.md)
- [Root README](../README.md)
