# 🖥️ Frontend CI Pipeline

> Builds and ships the Node.js frontend image, then updates the frontend Deployment in GitHub.

---

## ⚙️ Configuration

| Setting | Value |
|---------|-------|
| Job / script path | `jenkins/frontend/Jenkinsfile` |
| Build context | `app/frontend` |
| ECR repository | `020139096861.dkr.ecr.us-east-1.amazonaws.com/frontend` |
| Image tag | `${BUILD_NUMBER}` |
| Manifest updated | `k8s/frontend-deployment.yaml` |

---

## 🧱 Stages

1. **Build Image** — `buildImage(env.IMAGE, 'app/frontend')`
2. **Scan Image** — `scanImage(env.IMAGE)`
3. **Push Image** — `pushImage(env.IMAGE, env.REGISTRY, env.REGION)`
4. **Delete Image Locally** — `deleteImage(env.IMAGE)`
5. **Update Manifests** — `updateManifests('k8s/frontend-deployment.yaml', env.IMAGE)`
6. **Push Manifests** — `pushManifests(env.REPO)` with credential `github-creds`

The resulting `image:` line in the Deployment points at the ECR URL with the number of this build.

---

## 🔗 Related

- [pipelines overview](../README.md)
- [frontend source](../../app/frontend/README.md)
- [frontend Deployment](../../k8s/README.md)
