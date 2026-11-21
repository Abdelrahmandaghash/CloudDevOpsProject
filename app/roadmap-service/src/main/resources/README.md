# `src/main/resources/` — Spring Boot configuration

> Runtime configuration packaged inside the application jar.

## Contents

| File | Purpose |
|------|---------|
| `application.properties` | Sets `server.port=8080` — the port exposed by the container and the Kubernetes Service |

No database or external service configuration is needed: this service only returns static roadmap data.

## Related

- [main sources](../README.md)
- [roadmap service overview](../../../README.md)
