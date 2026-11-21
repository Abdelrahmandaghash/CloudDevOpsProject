# `jenkins/auth/Jenkinsfile` — auth pipeline

> Builds and ships the Python/Flask authentication service, then updates its Deployment in GitHub.

## Configuration

| Setting | Value |
|---------|-------|
| Job / script path | `jenkins/auth/Jenkinsfile` |
| Build context | `app/auth-service` |
| ECR repository | `020139096861.dkr.ecr.us-east-1.amazonaws.com/auth` |
| Image tag | `${BUILD_NUMBER}` |
| Manifest updated | `k8s/auth-deployment.yaml` |

## Stages

1. **Build Image** — `buildImage(env.IMAGE, 'app/auth-service')`
2. **Scan Image** — `scanImage(env.IMAGE)`
3. **Push Image** — `pushImage(env.IMAGE, env.REGISTRY, env.REGION)`
4. **Delete Image Locally** — `deleteImage(env.IMAGE)`
5. **Update Manifests** — `updateManifests('k8s/auth-deployment.yaml', env.IMAGE)`
6. **Push Manifests** — `pushManifests(env.REPO)` with credential `github-creds`

## Related

- [pipelines overview](../README.md)
- [auth source](../../app/auth-service/README.md)
- [auth Deployment and DB configuration](../../k8s/README.md)
