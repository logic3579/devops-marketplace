# Repository Guidelines

## Project Overview

This is a **Claude Code plugin marketplace** — a collection of Markdown prompt files, shell scripts, JSON manifests, and CI configuration. There is no compiled build step; validation is the primary quality gate.

## Project Structure

```
.claude-plugin/marketplace.json          — Marketplace registry (lists all plugins)
.github/workflows/validate-plugins.yml   — CI pipeline (4 validation jobs)
plugins/<name>/.claude-plugin/plugin.json — Plugin manifest
plugins/<name>/skills/<skill>/skill.md    — Skill prompt entrypoint
plugins/<name>/skills/<skill>/references/ — Domain knowledge (keep prompts <150 lines)
plugins/<name>/skills/<skill>/scripts/    — Helper shell scripts
plugins/<name>/agents/<agent>.md          — Agent definitions
plugins/<name>/hooks/<hook>.sh            — Hook scripts
.codex/INSTALL.md  .gemini/INSTALL.md  .opencode/INSTALL.md — Cross-tool install docs
```

## Current Plugins

| Plugin | Description |
|---|---|
| `cicd-automation` | CI/CD pipeline review & generation (GitHub Actions, GitLab CI) |
| `marketplace-tools` | Meta-tooling for the marketplace itself (skill-creator) |

A project-scoped `.mcp.json` at the repo root provides shared MCP server configs (GitHub, Sentry, K8s, Postgres, etc.) using `${ENV_VAR}` placeholders.

## Commands

```bash
# Validate a single plugin (pre-commit, CI gate)
claude plugin validate ./plugins/cicd-automation

# Validate ALL plugins
for dir in plugins/*/; do claude plugin validate "$dir"; done

# Dev mode: load and interactively test a plugin
claude --plugin-dir ./plugins/cicd-automation

# Run the SHA pinning security check standalone
./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh

# Shellcheck all scripts (CI does this too)
shellcheck -s bash -S warning $(find plugins -name '*.sh')

# Validate JSON manually
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"
```

## Code Style & Naming

### File naming
- All directories and files: **kebab-case**
- Skill entrypoint: always `skill.md`
- Agent files: `<name>.md`
- Hook/script files: `<name>.sh`

### Shell scripts (`*.sh`)
- Shebang: `#!/usr/bin/env bash`
- Second line: `set -euo pipefail`
- Must be executable: `chmod +x`
- Meaningful exit codes: `0` = ok, `1` = issues found, `2` = error
- Include a usage comment block at the top

### JSON manifests
- **Compact** formatting — no pretty-printing in manifests
- `plugin.json` must include `author` field
- `skills` / `agents` / `hooks` must be path strings or arrays of path strings (NOT object arrays)
- `version` in `plugin.json` must match `marketplace.json`
- `displayName`, `category`, `tags` are NOT valid in `plugin.json` (only in `marketplace.json`)

### Skill prompts (`skill.md`)
- YAML frontmatter with `name` and `description`
- Explicit PASS / WARN / FAIL criteria for every check item
- Structured output format (table template)
- Keep under 150 lines; move domain knowledge into `references/`
- 3–7 check categories, 2–6 checks per category

### Agent definitions (`agents/*.md`)
- YAML frontmatter with `name` and `description`
- Clear role definition, decision guidelines, tool usage guidance

## Adding a New Skill or Plugin

1. Create `plugins/<plugin>/skills/<skill-name>/skill.md` with YAML frontmatter
2. Add `references/` and `scripts/` subdirectories if needed
3. Ensure the plugin's `plugin.json` has `"skills": "./skills/"` pointing to the skills directory
4. If creating a new plugin, also register in `.claude-plugin/marketplace.json`
5. Run validation before committing:
   ```bash
   claude plugin validate ./plugins/<name>
   for dir in plugins/*/; do claude plugin validate "$dir"; done
   ```

## Testing

- Validate every changed plugin with `claude plugin validate`
- Run shell scripts manually to verify exit codes
- Test skills in dev mode (`claude --plugin-dir`) against realistic samples
- CI (`.github/workflows/validate-plugins.yml`) runs 4 checks on push/PR:
  - `validate-json` — JSON schema and required fields
  - `validate-entrypoints` — all paths in manifests resolve to real files
  - `validate-scripts` — scripts are executable and pass shellcheck
  - `validate-consistency` — version/name alignment, orphaned plugin detection

## Commit & PR Style

Use conventional prefixes: `feat:`, `fix:`, `chore:`. Keep subjects short and imperative.

**PR checklist:**
- List the validation commands you ran
- Include sample prompts or example usage when behavior changes
- Keep `version` aligned between `plugin.json` and `marketplace.json`

## Security

- Never commit secrets to manifests, scripts, or configs
- Use `${ENV_VAR}` placeholders in MCP configs (see `.mcp.json` at repo root)
- CI uses SHA-pinned GitHub Actions (enforced by `check-sha-pinning.sh`)
