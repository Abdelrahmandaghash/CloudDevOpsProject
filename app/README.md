# `app/` — application source code

> The three iVolve microservices. Each folder is a standalone project with its own Dockerfile,
> built both by `docker-compose.yml` locally and by a Jenkins pipeline for production.

Original application source: https://github.com/Ibrahim-Adel15/iVolveFinalProject.git

## Contents

| Folder | Technology | Port | Purpose |
|--------|-----------|------|---------|
| [`frontend/`](frontend/README.md) | Node.js 22, Express 5, EJS | 3000 | Web UI: login/signup forms, roadmap page, session handling |
| [`auth-service/`](auth-service/README.md) | Python 3.12, Flask 3 | 5000 | User registration and login, bcrypt password hashes, MySQL access |
| [`roadmap-service/`](roadmap-service/README.md) | Java 21, Spring Boot 3.5 | 8080 | REST API returning the 8 DevOps roadmap topics |

## How the services fit together

```
Browser ──> frontend (3000) ──> auth (5000) ──> MySQL (3306)
                         └────> roadmap (8080)
```

- `frontend` reads `AUTH_SERVICE_URL` and `ROADMAP_SERVICE_URL` to locate the two APIs.
- `auth` reads `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD` and creates its `users`
  table at startup if it does not exist.
- `roadmap` needs no configuration beyond `server.port=8080`.

## Running and building

```bash
# Whole stack locally (recommended):
docker compose -f ../docker-compose.yml up --build

# Or build an individual image:
docker build -t ivolve-frontend frontend
docker build -t ivolve-auth auth-service
docker build -t ivolve-roadmap roadmap-service
```

In the cluster these images come from ECR, and Jenkins rewrites the `image:` line in `k8s/`
whenever a pipeline succeeds.

## API surface

| Service | Endpoint | Description |
|---------|----------|-------------|
| auth | `GET /health` | Database connectivity check |
| auth | `POST /api/auth/signup` | Create a user account |
| auth | `POST /api/auth/login` | Verify credentials and start a session |
| roadmap | `GET /api/roadmap` | Return the DevOps roadmap items |
| frontend | `/`, `/login`, `/signup`, `/roadmap`, `/logout` | Server-rendered pages and session routes |

## Related

- [Root README](../README.md)
- [Docker Compose](../docker-compose.yml)
- [Jenkins pipelines](../jenkins/README.md)
- [Kubernetes manifests](../k8s/README.md)
