# Docker Compose reference

> There is no `docker/` folder in this repository — the Compose file lives at the repository root as
> [`docker-compose.yml`](../docker-compose.yml). This page is the short folder-style reference for it.
> The full line-by-line walkthrough is in [section 2 of the root README](../README.md#2-docker--local-container-stack).

## Purpose

Run the complete iVolve stack locally with one command, including MySQL, before touching AWS.

## Files involved

| File | Role |
|---|---|
| [`docker-compose.yml`](../docker-compose.yml) | Defines the four services, one named volume and the health gate |
| [`app/frontend/Dockerfile`](../app/frontend/Dockerfile) | Builds the Node.js 22 frontend image |
| [`app/auth-service/Dockerfile`](../app/auth-service/Dockerfile) | Builds the Python 3.12 Flask image |
| [`app/roadmap-service/Dockerfile`](../app/roadmap-service/Dockerfile) | Multi-stage Maven + Java 21 image |

## Services, ports and inputs

| Service | Image / build | Host port | Container port | Key inputs | Depends on |
|---|---|---:|---:|---|---|
| `db` | `mysql:8` | — | 3306 | `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE=ivolve` | — |
| `auth-service` | `./app/auth-service` | 5000 | 5000 | `DB_HOST=db`, `DB_PORT=3306`, `DB_NAME=ivolve`, `DB_USER=root`, `DB_PASSWORD` | `db` (healthy) |
| `roadmap-service` | `./app/roadmap-service` | 8080 | 8080 | none | `auth-service` |
| `frontend` | `./app/frontend` | 80 | 3000 | `AUTH_SERVICE_URL`, `ROADMAP_SERVICE_URL`, `SESSION_SECRET` | `auth-service`, `roadmap-service` |

**Volumes:** `db-data:/var/lib/mysql` is the only named volume.

**Network:** Compose's default bridge network; services resolve each other by service name (`db`,
`auth-service`, `roadmap-service`).

**Healthcheck:** `mysqladmin ping -h localhost` every 5 s, 5 s timeout, 20 retries.
`auth-service` starts only when it reports `service_healthy`.

## Commands

```bash
cd <repo-root>
docker compose config          # read-only validation of the file
docker compose up --build      # build and start everything
docker compose ps              # check health and ports
curl http://localhost/         # frontend (host 80 -> container 3000)
curl http://localhost:5000/health
curl http://localhost:8080/api/roadmap
docker compose logs -f auth-service
docker compose down            # stop; keep the database volume
docker compose down -v         # stop and DELETE the database volume
```

## Expected output

- `docker compose ps` shows four services; `db` is `healthy`.
- `http://localhost/` renders the iVolve login page with both logos.
- Signup → login → roadmap page with eight cards.
- `GET /health` returns `{"status":"UP","database":"connected"}`.

## Security note

The Compose file contains hard-coded **development-only** values for `MYSQL_ROOT_PASSWORD`,
`DB_PASSWORD` and `SESSION_SECRET` (shown here only as `<DB_PASSWORD>` / `<SESSION_SECRET>`). They
are suitable for local use only. Never copy them into the Kubernetes manifests or a production
environment, and move them to an untracked `.env` file; see
[Security considerations](../README.md#-security-notes).
