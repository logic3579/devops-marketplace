# GitHub Actions Best Practices Reference

## SHA Pinning

Always pin third-party actions to a full 40-character commit SHA:

```yaml
# Bad - mutable tag
- uses: actions/checkout@v4

# Good - pinned SHA
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
```

Use tools like `pin-github-action` or Dependabot to keep pinned SHAs up to date.

## Permissions

Set restrictive default permissions at the workflow level, then escalate per-job:

```yaml
permissions:
  contents: read

jobs:
  build:
    permissions:
      contents: read
  deploy:
    permissions:
      contents: read
      deployments: write
```

Never use `permissions: write-all` or leave permissions unset (defaults to broad access in older repos).

## Expression Injection Prevention

Untrusted inputs in `${{ }}` expressions can execute arbitrary code:

```yaml
# VULNERABLE - attacker-controlled PR title injected into shell
- run: echo "PR: ${{ github.event.pull_request.title }}"

# SAFE - use environment variable
- run: echo "PR: $PR_TITLE"
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
```

Untrusted contexts include:
- `github.event.issue.title` / `.body`
- `github.event.pull_request.title` / `.body` / `.head.ref`
- `github.event.comment.body`
- `github.event.review.body`
- `github.event.discussion.title` / `.body`
- `github.head_ref`

## Concurrency

Prevent parallel deployments with concurrency groups:

```yaml
concurrency:
  group: deploy-${{ github.ref }}
  cancel-in-progress: false  # for deployments, don't cancel in-progress
```

For PR CI, cancelling in-progress runs saves resources:

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

## Caching

Use `actions/cache` or built-in setup action caching:

```yaml
- uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
  with:
    node-version: 20
    cache: 'npm'
```

For custom caching, use a composite key with fallback:

```yaml
- uses: actions/cache@5a3ec84eff668545956fd18022155c47e93e2684 # v4.2.3
  with:
    path: ~/.cache/pip
    key: pip-${{ runner.os }}-${{ hashFiles('**/requirements*.txt') }}
    restore-keys: |
      pip-${{ runner.os }}-
```

## Reusable Workflows

Extract common patterns into reusable workflows:

```yaml
# .github/workflows/reusable-build.yml
on:
  workflow_call:
    inputs:
      node-version:
        type: string
        default: '20'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2
      - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020 # v4.4.0
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci && npm run build
```

## Timeouts

Always set explicit timeouts to prevent hung jobs:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 15
```

Default timeout is 360 minutes (6 hours) which wastes runner minutes if a job hangs.

## Environment Protection

Use environments for production deployments:

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://example.com
    runs-on: ubuntu-latest
```

Configure environment protection rules in repo settings:
- Required reviewers
- Wait timer
- Deployment branches restriction

## OpenID Connect (OIDC)

Prefer OIDC over long-lived credentials for cloud deployments:

```yaml
permissions:
  id-token: write
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@e3dd6a429d7300a6a4c196c26e071d42e0343502 # v4.0.2
    with:
      role-to-assume: arn:aws:iam::123456789:role/deploy
      aws-region: us-east-1
```
