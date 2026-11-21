# `com/ivolve/roadmap` — application package

> The two Java classes that make up the Spring Boot service.

## Contents

| File | Purpose |
|------|---------|
| `RoadmapApplication.java` | `@SpringBootApplication`; `main()` calls `SpringApplication.run(...)` |
| `RoadmapController.java` | `@RestController`; `GET /api/roadmap` returns the eight DevOps roadmap topics |

The controller returns static data: Operating Systems, SCM, Containerization, Container Orchestration,
CI/CD, Cloud, Infrastructure as Code and Configuration Management.

## Related

- [organisation package](../README.md)
- [roadmap service overview](../../../../../../README.md)
