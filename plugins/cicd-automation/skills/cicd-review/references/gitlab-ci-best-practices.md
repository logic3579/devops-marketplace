# GitLab CI Best Practices Reference

## Pipeline Structure

### Use `rules:` instead of `only/except`

```yaml
# Deprecated
deploy:
  only:
    - main

# Modern
deploy:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

### DAG with `needs:`

Use `needs:` to create a directed acyclic graph for parallel execution:

```yaml
stages:
  - build
  - test
  - deploy

build_frontend:
  stage: build
  script: npm run build

build_backend:
  stage: build
  script: go build ./...

test_frontend:
  stage: test
  needs: [build_frontend]
  script: npm test

test_backend:
  stage: test
  needs: [build_backend]
  script: go test ./...

deploy:
  stage: deploy
  needs: [test_frontend, test_backend]
  script: ./deploy.sh
```

## Security

### Protected Variables

Sensitive variables should be:
- Marked as **Protected** (only available on protected branches/tags)
- Marked as **Masked** (hidden in job logs)
- Scoped to specific environments when possible

```yaml
deploy_production:
  variables:
    DEPLOY_TOKEN: $PRODUCTION_DEPLOY_TOKEN  # Protected + Masked variable
  environment:
    name: production
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
```

### Container Scanning

```yaml
include:
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
```

### Runner Security

- Use tagged runners to control which runners execute sensitive jobs
- Never run untrusted code on privileged runners
- Clean up workspaces between jobs on shared runners

```yaml
deploy:
  tags:
    - production-runner
    - privileged
```

## Caching

### Per-branch cache with fallback

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_COMMIT_REF_SLUG
  paths:
    - node_modules/
  policy: pull-push
```

### Cache vs Artifacts

| Feature | Cache | Artifacts |
|---------|-------|-----------|
| Purpose | Speed up jobs (dependencies) | Pass data between jobs/stages |
| Availability | Best-effort, may miss | Guaranteed within pipeline |
| Storage | Runner-local or distributed | GitLab server |
| Use for | `node_modules/`, `.cache/pip` | Build outputs, test reports |

## Timeouts

```yaml
default:
  timeout: 15m  # Global default

long_running_job:
  timeout: 45m  # Per-job override
  script: ./run-integration-tests.sh
```

## Environment Management

```yaml
deploy_staging:
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop_staging
    auto_stop_in: 1 week
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

stop_staging:
  environment:
    name: staging
    action: stop
  when: manual
```

## Artifacts and Reports

```yaml
test:
  script: pytest --junitxml=report.xml --cov=app --cov-report=xml
  artifacts:
    reports:
      junit: report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    expire_in: 30 days
  coverage: '/^TOTAL.*\s+(\d+\%)$/'
```

## Includes and Templates

### Reusable job templates

```yaml
.deploy_template:
  image: alpine:3.19
  before_script:
    - apk add --no-cache curl
  script:
    - ./deploy.sh $ENVIRONMENT
  after_script:
    - ./notify.sh

deploy_staging:
  extends: .deploy_template
  variables:
    ENVIRONMENT: staging
  environment:
    name: staging

deploy_production:
  extends: .deploy_template
  variables:
    ENVIRONMENT: production
  environment:
    name: production
  when: manual
```

### Remote includes

```yaml
include:
  - project: 'devops/ci-templates'
    ref: main
    file: '/templates/docker-build.yml'
  - remote: 'https://example.com/ci/shared.yml'
```

## Interruptible Jobs

Mark CI jobs as interruptible so new pushes cancel outdated pipelines:

```yaml
default:
  interruptible: true

deploy:
  interruptible: false  # Never cancel deployments
```
