# `app/roadmap-service/` — Java DevOps roadmap API

> Spring Boot service on port **8080**. It exposes one read-only endpoint returning the eight DevOps
> roadmap topics rendered by the frontend. It has no database dependency.

## Contents

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage build: Maven 3.9 + JDK 21 builds the jar, `eclipse-temurin:21-jre` runs it |
| `pom.xml` | Spring Boot 3.5.4 parent, `com.ivolve:roadmap-service:1.0.0`, Java 21, `spring-boot-starter-web` |
| `src/main/java/com/ivolve/roadmap/RoadmapApplication.java` | `@SpringBootApplication` entry point |
| `src/main/java/com/ivolve/roadmap/RoadmapController.java` | `@RestController` with `GET /api/roadmap` |
| `src/main/resources/application.properties` | `server.port=8080` |

The multi-stage Dockerfile produces `roadmap-service-1.0.0.jar`, copied into the runtime image as
`app.jar` and started with `java -jar app.jar`.

## API

`GET /api/roadmap` returns eight items in learning order:

1. Operating Systems
2. Source Control Management
3. Containerization
4. Container Orchestration
5. CI/CD
6. Cloud
7. Infrastructure as Code
8. Configuration Management

## Run locally

```bash
mvn clean package -DskipTests
java -jar target/roadmap-service-1.0.0.jar

# or build the container
docker build -t ivolve-roadmap .
```

Kubernetes needs no environment variables for this service — only the image tag in
`k8s/roadmap-deployment.yaml`, which Jenkins maintains.

## Related

- [app overview](../README.md)
- [frontend](../frontend/README.md)
- [roadmap pipeline](../../jenkins/roadmap/README.md)
- [roadmap Deployment / Service](../../k8s/README.md)
