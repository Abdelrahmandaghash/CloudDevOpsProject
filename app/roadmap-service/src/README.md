# `src/` — Maven source root

> Standard Maven source tree for the Spring Boot roadmap service.

## Contents

| Folder | Purpose |
|--------|---------|
| [`main/`](main/README.md) | Application Java code and runtime configuration |

There are no test sources in this project. The Dockerfile builds the application with
`mvn clean package -DskipTests`, which produces `roadmap-service-1.0.0.jar`.

## Related

- [roadmap service overview](../README.md)
