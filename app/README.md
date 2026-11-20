# Application source code lives here (added by you, not part of the zip):

    app/frontend/         Node.js / Express / EJS   port 3000  (UI)
    app/auth-service/     Python / Flask            port 5000  (signup + login, uses MySQL)
    app/roadmap-service/  Java / Spring Boot        port 8080  (DevOps roadmap data)

Source: https://github.com/Ibrahim-Adel15/iVolveFinalProject.git

Note: the URL in the original README said `IbrahimAdel15` (no hyphen) — that
account does not exist. The real one is `Ibrahim-Adel15`.

Each folder contains its own Dockerfile, which is what docker-compose.yml and
the Jenkins pipelines build.
