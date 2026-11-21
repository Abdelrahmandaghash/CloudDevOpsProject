# `app/frontend/` — Node.js web UI

> Express + EJS frontend on port **3000**. It renders the login/signup pages and the authenticated
> roadmap page, and proxies API calls to `auth` and `roadmap`.

## Contents

| File | Purpose |
|------|---------|
| `Dockerfile` | `node:22-alpine`, installs production dependencies, exposes 3000, runs `npm start` |
| `package.json` | Package `ivolve-frontend` v1.0.0 — express 5, ejs 3, axios 1, express-session 1 |
| `server.js` | Express application: session middleware, routes, API proxying, error view |
| `views/auth.ejs` | Login and signup form (username ≥ 3 chars, password ≥ 8 chars) with NTI/iVolve logos |
| `views/roadmap.ejs` | Authenticated page: navigation, numbered roadmap cards, logout form |
| `views/error.ejs` | Error page shown when a backend or database call fails (HTTP 503) |
| `public/css/style.css` | Dark-theme responsive styling: auth card, navigation, 4/2/1-column grid |
| `public/images/` | `ivolve-logo.png`, `nti-logo.png` |

## Configuration

| Environment variable | Default | Description |
|----------------------|---------|-------------|
| `AUTH_SERVICE_URL` | `http://localhost:5000` | Base URL of the auth API (`http://auth:5000` in Kubernetes) |
| `ROADMAP_SERVICE_URL` | `http://localhost:8080` | Base URL of the roadmap API (`http://roadmap:8080` in Kubernetes) |
| `SESSION_SECRET` | `change-me-in-k8s` | Secret used to sign the session cookie (httpOnly, 1 hour) |

## Routes

| Route | Method | Behaviour |
|-------|--------|-----------|
| `/` | GET | Redirect to login or roadmap depending on the session |
| `/login`, `/signup` | GET | Render the auth form |
| `/login`, `/signup` | POST | Forward credentials to the auth API; create the session |
| `/roadmap` | GET | Session-gated; fetch roadmap items from the roadmap API |
| `/logout` | POST | Destroy the session |

When an upstream service fails, the server renders `views/error.ejs` with status 503.

## Run

```bash
npm install
AUTH_SERVICE_URL=http://localhost:5000 \
ROADMAP_SERVICE_URL=http://localhost:8080 \
npm start
```

Or use the [root Docker Compose](../../docker-compose.yml), which supplies all variables.

## Related

- [app overview](../README.md)
- [auth service](../auth-service/README.md)
- [roadmap service](../roadmap-service/README.md)
- [frontend pipeline](../../jenkins/frontend/README.md)
- [frontend Deployment / Service](../../k8s/README.md)
