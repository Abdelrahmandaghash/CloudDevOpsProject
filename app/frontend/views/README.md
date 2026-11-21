# `app/frontend/views/` — EJS templates

> Server-rendered pages for the Express frontend, rendered with `res.render(...)`.

## Contents

| File | Rendered for | Purpose |
|------|--------------|---------|
| `auth.ejs` | `/login`, `/signup` | Username/password form (min 3 / 8 characters), logos, links between login and signup |
| `roadmap.ejs` | `/roadmap` | Authenticated page: navigation, numbered roadmap cards, logout form |
| `error.ejs` | backend errors | Error message with status 503 and a link back to `/` |

All templates load `/css/style.css` and the logos from `/images/`. Session data supplied by
`server.js` decides whether a visitor sees the auth form or the roadmap.

## Related

- [frontend overview](../README.md)
- [static assets](../public/README.md)
