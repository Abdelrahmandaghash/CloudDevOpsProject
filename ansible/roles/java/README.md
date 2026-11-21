# `ansible/roles/java` — Java runtime

> Installs the Java runtime required by Jenkins.

## Contents

| File | Purpose |
|------|---------|
| `tasks/main.yml` | Installs `openjdk-21-jre` with `update_cache: yes`, state `present` |

## Details

Current Jenkins releases require **Java 21** or newer. The role uses `openjdk-21-jre` (runtime only —
the Jenkins war ships with what it needs). The task is idempotent: re-running the playbook reports
`ok` rather than reinstalling.

## Related

- [roles overview](../README.md)
- [jenkins role](../jenkins/README.md)
