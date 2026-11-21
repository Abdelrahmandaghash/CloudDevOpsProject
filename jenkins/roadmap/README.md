# `jenkins/roadmap/Jenkinsfile` — roadmap pipeline

> Builds and ships the Java/Spring Boot roadmap service, then updates its Deployment in GitHub.

## Configuration

| Setting | Value |
|---------|-------|
| Job / script path | `jenkins/roadmap/Jenkinsfile` |
| Build context | `app/roadmap-service` |
| ECR repository | `020139096861.dkr.ecr.us-east-1.amazonaws.com/roadmap` |
| Image tag | `${BUILD_NUMBER}` |
| Manifest updated | `k8s/roadmap-deployment.yaml` |

## Stages

1. **Build Image** — `buildImage(env.IMAGE, 'app/roadmap-service')`
2. **Scan Image** — `scanImage(env.IMAGE)`
3. **Push Image** — `pushImage(env.IMAGE, env.REGISTRY, env.REGION)`
4. **Delete Image Locally** — `deleteImage(env.IMAGE)`
5. **Update Manifests** — `updateManifests('k8s/roadmap-deployment.yaml', env.IMAGE)`
6. **Push Manifests** — `pushManifests(env.REPO)` with credential `github-creds`

The multi-stage Dockerfile performs the Maven build, so the pipeline itself only needs Docker.

## Related

- [pipelines overview](../README.md)
- [roadmap source](../../app/roadmap-service/README.md)
- [roadmap Deployment](../../k8s/README.md)
