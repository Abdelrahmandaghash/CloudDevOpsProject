# `app/auth-service/` — Python authentication API

> Flask service on port **5000**. It is the only microservice that talks to MySQL: it creates the
> `users` table, hashes passwords with bcrypt, and exposes signup/login/health endpoints.

## Contents

| File | Purpose |
|------|---------|
| `Dockerfile` | `python:3.12-slim`, installs `requirements.txt`, exposes 5000, runs `python app.py` |
| `requirements.txt` | Pinned dependencies: `Flask==3.1.1`, `mysql-connector-python==9.4.0`, `bcrypt==4.3.0` |
| `app.py` | Flask application: DB connection with startup retry, schema creation, API endpoints |

## Configuration

All settings are read from environment variables and validated at startup:

| Variable | Example (local) | Example (Kubernetes) |
|----------|-----------------|----------------------|
| `DB_HOST` | `db` | `mysql-0.mysql` (via ConfigMap `app-config`) |
| `DB_PORT` | `3306` | `3306` |
| `DB_NAME` | `ivolve` | `ivolve` |
| `DB_USER` | `root` | `root` |
| `DB_PASSWORD` | `rootpassword` | from Secret `app-secret` |

The service retries the MySQL connection up to **30 times with a 2-second gap**, so it can start
before the database healthcheck passes.

## API

| Method | Path | Responses |
|--------|------|-----------|
| GET | `/health` | 200 when the DB is reachable, 503 otherwise |
| POST | `/api/auth/signup` | 201 created · 400 invalid input · 409 duplicate username · 503 DB error |
| POST | `/api/auth/login` | 200 success · 401 bad credentials · 503 DB error |

The `users` table has `id`, a unique `username`, a bcrypt `password_hash` and `created_at`.

## Run

```bash
pip install -r requirements.txt
DB_HOST=localhost DB_PORT=3306 DB_NAME=ivolve DB_USER=root DB_PASSWORD=rootpassword \
python app.py
```

Or use the [root Docker Compose](../../docker-compose.yml), which supplies all variables.

## Related

- [app overview](../README.md)
- [frontend](../frontend/README.md)
- [auth pipeline](../../jenkins/auth/README.md)
- [auth Deployment / Service and DB config](../../k8s/README.md)
