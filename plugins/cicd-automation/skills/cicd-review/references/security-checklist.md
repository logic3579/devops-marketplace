# CI/CD Security Checklist

## Supply Chain Security

### Third-Party Actions
- [ ] All actions pinned to full commit SHA
- [ ] Actions sourced from verified creators or well-known organizations
- [ ] No actions from forks or unknown publishers
- [ ] Dependabot or Renovate configured for automated SHA updates

### Container Images
- [ ] Base images pinned to digest (`image@sha256:abc...`), not just tags
- [ ] Images sourced from trusted registries
- [ ] Image scanning enabled (Trivy, Snyk, Grype)

### Dependencies
- [ ] Lock files committed (`package-lock.json`, `poetry.lock`, `go.sum`)
- [ ] Dependency review enabled for PRs
- [ ] SBOM generation for release artifacts

## Secrets Management

### Storage
- [ ] No secrets in code, config files, or environment variable defaults
- [ ] All secrets stored in platform secret store (GitHub Secrets, GitLab CI/CD Variables)
- [ ] Secrets scoped to minimum required level (environment > repo > org)
- [ ] Secret scanning enabled on the repository

### Usage
- [ ] Secrets not logged (mask with `::add-mask::` if dynamically generated)
- [ ] Secrets not passed as command-line arguments (visible in process lists)
- [ ] Secrets not interpolated in `${{ }}` expressions in `run:` blocks
- [ ] Temporary credentials (OIDC tokens) preferred over long-lived secrets

## Workflow Permissions

### GitHub Actions
- [ ] `permissions` explicitly set at workflow level
- [ ] Each job has its own minimal `permissions` block
- [ ] `GITHUB_TOKEN` permissions follow least privilege
- [ ] No `permissions: write-all`
- [ ] `pull_request_target` workflows do NOT checkout PR code with write permissions

### GitLab CI
- [ ] Protected variables only available on protected branches
- [ ] CI/CD variables masked where possible
- [ ] `rules:` used instead of deprecated `only/except`

## Dangerous Patterns

### pull_request_target
```yaml
# DANGEROUS: checks out attacker-controlled code with write token
on: pull_request_target
steps:
  - uses: actions/checkout@v4
    with:
      ref: ${{ github.event.pull_request.head.sha }}
  - run: make build  # executes attacker code with elevated privileges
```

**Mitigation**: Use `pull_request` trigger, or if `pull_request_target` is needed, never checkout or execute PR code in the same job that has elevated permissions.

### workflow_run
```yaml
# CAUTION: inherits elevated privileges from triggering workflow
on:
  workflow_run:
    workflows: ["Build"]
    types: [completed]
```

**Mitigation**: Validate the triggering workflow's conclusion and branch. Do not blindly trust artifacts from `workflow_run`.

### Self-hosted Runners
- [ ] Self-hosted runners not used for public repositories (or heavily sandboxed)
- [ ] Runner workspaces cleaned between jobs
- [ ] Runners isolated per security boundary (don't share between prod and untrusted)

## Artifact Security
- [ ] Artifacts do not contain secrets or credentials
- [ ] Artifact retention set to minimum needed
- [ ] Release artifacts signed or checksummed
- [ ] Artifact upload/download uses latest action version (pinned to SHA)

## Network Security
- [ ] Egress from CI jobs restricted where possible
- [ ] No `curl | bash` patterns for installing tools (use pinned package managers)
- [ ] TLS verification not disabled
- [ ] Proxy/firewall rules in place for self-hosted runners
