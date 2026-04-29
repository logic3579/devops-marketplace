# CLAUDE.md

This is a Claude Code plugin marketplace repository. It contains reusable plugins (skills, agents, hooks) for DevOps automation.

## Project Structure

```
.claude-plugin/marketplace.json    — Marketplace registry (lists all plugins)
plugins/<name>/.claude-plugin/plugin.json — Plugin manifest (skills, agents, hooks)
plugins/<name>/skills/<skill>/skill.md    — Skill prompt entrypoint
plugins/<name>/skills/<skill>/references/ — Domain knowledge for the skill
plugins/<name>/skills/<skill>/scripts/    — Supporting shell scripts
plugins/<name>/agents/<agent>.md          — Agent definitions
plugins/<name>/hooks/<hook>.sh            — Hook scripts
```

## Current Plugins

- **cicd-automation** — CI/CD pipeline review & generation (GitHub Actions, GitLab CI)
- **marketplace-tools** — Meta-tooling for the marketplace itself (skill-creator, changelog-generator)

A project-scoped `.mcp.json` at the repo root provides shared MCP server configurations (GitHub, Sentry, GCloud, Kubernetes, ClickHouse, MySQL, Postgres, Slack, Linear, Grafana, Filesystem) using `${ENV_VAR}` placeholders.

## Key Rules

- All shell scripts must use `#!/usr/bin/env bash` and `set -euo pipefail`
- All shell scripts must be executable (`chmod +x`)
- Skill prompts (`skill.md`) must have: YAML frontmatter with `name` and `description` fields, role definition, check items with pass/fail criteria, output format template
- Agent definitions (`.md`) must have YAML frontmatter with `name` and `description` fields
- `plugin.json` schema: `skills`/`agents` must be path strings or arrays of path strings (not object arrays); `displayName`/`category`/`tags` are NOT valid fields (use `marketplace.json` for category/tags)
- `plugin.json` must include `author` field
- `version` in `plugin.json` must match the corresponding entry in `marketplace.json`
- Reference documents go in `references/`, not inline in skill prompts
- CI workflow at `.github/workflows/validate-plugins.yml` validates structure on every push/PR

## Naming Conventions

- Directories and files: `kebab-case`
- Skill entrypoint: always `skill.md`
- Agent files: `<name>.md`
- Hook/script files: `<name>.sh`

## When Adding a New Skill

1. Create `plugins/<plugin>/skills/<skill-name>/skill.md` (with YAML frontmatter)
2. Add `references/` and `scripts/` subdirs if needed
3. Ensure the plugin's `plugin.json` has `"skills": "./skills/"` pointing to the skills directory
4. If creating a new plugin, also register in `.claude-plugin/marketplace.json`

## When Editing Skill Prompts

- Every check item must have explicit PASS/WARN/FAIL criteria
- Output format must use the structured table template (see existing skills for examples)
- Keep prompts under 150 lines; move domain knowledge to `references/`

## Testing

```bash
# Validate plugin structure
claude plugin validate ./plugins/<name>

# Dev mode: load and test interactively
claude --plugin-dir ./plugins/<name>

# Run SHA pinning check script
./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh
```
