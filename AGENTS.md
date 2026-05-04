# Repository Guidelines

## Project Overview

This is a **Claude Code plugin marketplace** — a curated collection of Markdown prompt files, shell scripts, JSON manifests, and CI configuration. There is no compiled build step; validation is the primary quality gate.

The same content is also exposed to Codex, Gemini CLI, and OpenCode via tool-native configs and `INSTALL.md` guides under `.codex/`, `.gemini/`, and `.opencode/`.

## Project Structure

```
.claude-plugin/marketplace.json           — Marketplace registry (lists all plugins)
.mcp.json                                 — Project-scoped MCP servers (3 stdio servers)
.github/workflows/validate-plugins.yml    — CI: 4 validation jobs
.claude/                                  — Claude Code project settings
.codex/   .gemini/   .opencode/           — Cross-tool install docs + tool-native configs
plugins/<name>/.claude-plugin/plugin.json — Plugin manifest
plugins/<name>/skills/<skill>/skill.md    — Skill prompt (entrypoint)
plugins/<name>/skills/<skill>/references/ — Domain knowledge (keep prompts <150 lines)
plugins/<name>/skills/<skill>/scripts/    — Helper shell scripts
plugins/<name>/agents/<agent>.md          — Agent definitions
plugins/<name>/hooks/<hook>.sh            — Hook scripts
skills/<skill>/skill.md                   — Repo-level skills (not packaged in any plugin)
README.md   CLAUDE.md   GEMINI.md         — Top-level docs (per-tool / general)
```

## Current Plugins

| Plugin | Version | Description |
|---|---|---|
| `cicd-automation` | 1.0.0 | CI/CD pipeline review & generation (GitHub Actions, GitLab CI) |

**`cicd-automation` contents:**

| Component | Name | Description |
|---|---|---|
| Skill | `cicd-review` | Audits pipelines across security, reliability, performance, maintainability, compliance |
| Skill | `pipeline-generator` | Generates production-ready pipelines (SHA-pinned, least-privilege, cached, timed-out) |
| Agent | `cicd-agent` | Full-lifecycle agent: review, generate, diagnose, and fix |
| Hook | `workflow-lint.sh` | Pre-commit YAML + SHA-pin lint |
| Script | `check-sha-pinning.sh` | Standalone scanner for unpinned third-party actions |

## Repo-Level Skills

Standalone skills under `skills/`, not packaged into any plugin:

| Skill | Description |
|---|---|
| `skill-creator` | Scaffold new skills with proper structure and manifest entries |
| `changelog-generator` | Generate user-facing changelogs from git history |

## Shared MCP Servers

`.mcp.json` at the repo root provides 3 stdio MCP servers loaded automatically by Claude Code from this directory; sensitive values use `${ENV_VAR}` placeholders. The same set is mirrored into `.codex/config.toml`, `.gemini/settings.json`, and `.opencode/opencode.json`.

| Server | Launcher | Purpose |
|---|---|---|
| `clickhouse` | `uvx mcp-clickhouse` | ClickHouse database access |
| `gcloud` | `npx @google-cloud/gcloud-mcp` | Google Cloud Platform |
| `kubernetes` | `npx kubernetes-mcp-server --read-only` | Kubernetes (read-only) |

## Cross-Tool Support

| Tool | Install doc | Mechanism |
|---|---|---|
| Claude Code | `README.md` | Native marketplace via `/plugin marketplace add` |
| Codex | `.codex/INSTALL.md` | Symlink skills into `~/.agents/skills/` |
| Gemini CLI | `.gemini/INSTALL.md` | `gemini extensions install <repo-url>` |
| OpenCode | `.opencode/INSTALL.md` | `plugin` array entry in `opencode.json` |

Codex / Gemini / OpenCode consume **skills only**. Claude-specific marketplace metadata, agents, and hooks are loaded only by Claude Code.

## Commands

```bash
# Validate a single plugin
claude plugin validate ./plugins/cicd-automation

# Validate ALL plugins
for dir in plugins/*/; do claude plugin validate "$dir"; done

# Dev mode: load and interactively test a plugin
claude --plugin-dir ./plugins/cicd-automation

# Run the SHA-pinning scanner standalone
./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh

# Shellcheck all plugin scripts (CI does this too)
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
- Must be executable (`chmod +x`)
- Meaningful exit codes: `0` = ok, `1` = issues found, `2` = error
- Include a usage comment block at the top

### JSON manifests
- Compact formatting — no pretty-printing in manifests
- `plugin.json` must include `name`, `version`, `description`, `author`
- `skills` / `agents` / `hooks` must be path strings or arrays of path strings (NOT object arrays)
- `version` in `plugin.json` must match `marketplace.json`
- `displayName`, `category`, `tags` are NOT valid in `plugin.json` — only in `marketplace.json`

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
2. Add `references/` and `scripts/` subdirectories only if needed
3. Ensure the plugin's `plugin.json` has `"skills": "./skills/"` pointing to the skills directory
4. If creating a new plugin, also register it in `.claude-plugin/marketplace.json`
5. If the skill should ship to Codex / Gemini / OpenCode, update the relevant `INSTALL.md`
6. Run validation before committing:
   ```bash
   claude plugin validate ./plugins/<name>
   for dir in plugins/*/; do claude plugin validate "$dir"; done
   ```

## Testing

- Validate every changed plugin with `claude plugin validate`
- Run shell scripts manually to verify exit codes
- Test skills in dev mode (`claude --plugin-dir`) against realistic samples
- CI (`.github/workflows/validate-plugins.yml`) runs 4 jobs on push/PR (paths: `.claude-plugin/**`, `plugins/**`):
  - `validate-json` — `marketplace.json` + every `plugin.json` has required fields
  - `validate-entrypoints` — all manifest paths resolve to real files
  - `validate-scripts` — scripts are executable and pass shellcheck
  - `validate-consistency` — version/name alignment, no orphaned plugins
- All CI actions are SHA-pinned; default permissions are `contents: read`

## Commit & PR Style

Use conventional prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`. Keep subjects short and imperative.

**PR checklist:**
- List the validation commands you ran
- Include sample prompts or example usage when behavior changes
- Bump `version` in both `plugin.json` and `marketplace.json` together
- Update the relevant `INSTALL.md` if the change affects Codex / Gemini / OpenCode users

## Security

- Never commit secrets to manifests, scripts, or configs
- Use `${ENV_VAR}` placeholders in MCP configs (`.mcp.json`, `.codex/config.toml`, `.gemini/settings.json`, `.opencode/opencode.json`)
- CI uses SHA-pinned GitHub Actions (enforced by `check-sha-pinning.sh`)
- Default to least-privilege permissions; justify any write access
- Default to read-only MCP servers where the upstream supports it (e.g. `kubernetes-mcp-server --read-only`)
