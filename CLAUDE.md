# CLAUDE.md

This is a **Claude Code plugin marketplace** repository. It hosts reusable plugins (skills, agents, hooks) for DevOps automation, plus repo-level standalone skills and cross-tool installation docs (Codex / Gemini CLI / OpenCode).

There is no compiled build step. Validation (CI + `claude plugin validate`) is the primary quality gate.

## Project Structure

```
.claude-plugin/marketplace.json           — Marketplace registry (lists all plugins)
.mcp.json                                 — Project-scoped MCP servers (3 stdio servers)
.github/workflows/validate-plugins.yml    — CI: 4 validation jobs
.claude/                                  — Claude Code project settings (settings.json, settings.local.json)
.codex/   .gemini/   .opencode/           — Cross-tool install docs + tool-native configs
plugins/<name>/.claude-plugin/plugin.json — Plugin manifest
plugins/<name>/skills/<skill>/skill.md    — Skill prompt (entrypoint)
plugins/<name>/skills/<skill>/references/ — Domain knowledge (keep prompts <150 lines)
plugins/<name>/skills/<skill>/scripts/    — Supporting shell scripts
plugins/<name>/agents/<agent>.md          — Agent definitions
plugins/<name>/hooks/<hook>.sh            — Hook scripts
skills/<skill>/skill.md                   — Repo-level skills (not packaged in any plugin)
README.md   AGENTS.md   GEMINI.md         — Top-level docs (per-tool)
```

## Current Plugins

| Plugin | Version | Description |
|---|---|---|
| `cicd-automation` | 1.0.0 | CI/CD pipeline review & generation (GitHub Actions, GitLab CI). 2 skills, 1 agent, 1 hook. |

`cicd-automation` ships:
- Skills: `cicd-review`, `pipeline-generator`
- Agent: `cicd-agent`
- Hook: `workflow-lint.sh` (pre-commit YAML + SHA-pin lint)
- Script: `check-sha-pinning.sh` (standalone scanner)

## Repo-Level Skills

Standalone skills under `skills/`, not packaged in any plugin:

| Skill | Description |
|---|---|
| `changelog-generator` | Generate user-facing changelogs from git history |

## Shared MCP Servers

A project-scoped `.mcp.json` at the repo root provides 3 stdio MCP servers, loaded automatically when Claude Code launches from this directory. Sensitive values use `${ENV_VAR}` placeholders.

| Server | Launcher | Purpose |
|---|---|---|
| `clickhouse` | `uvx mcp-clickhouse` | ClickHouse database access |
| `gcloud` | `npx @google-cloud/gcloud-mcp` | Google Cloud Platform |
| `kubernetes` | `npx kubernetes-mcp-server --read-only` | Kubernetes (read-only) |

The same set is mirrored into the tool-native configs (`.codex/config.toml`, `.gemini/settings.json`, `.opencode/opencode.json`) so all four tools see the same servers.

## Cross-Tool Support

| Tool | Install doc | Notes |
|---|---|---|
| Claude Code | `README.md` | Native — registers as a marketplace via `/plugin marketplace add` |
| Codex | `.codex/INSTALL.md` | Symlink skills into `~/.agents/skills/` |
| Gemini CLI | `.gemini/INSTALL.md` | `gemini extensions install <repo-url>` |
| OpenCode | `.opencode/INSTALL.md` | `plugin` array entry in `opencode.json` |

Codex/Gemini/OpenCode load **skills only** — Claude-specific marketplace metadata, agents, and hooks are not consumed by the other tools.

## Key Rules

- All shell scripts: `#!/usr/bin/env bash` + `set -euo pipefail`, executable (`chmod +x`)
- Skill prompts (`skill.md`): YAML frontmatter with `name` and `description`, role definition, checks with explicit PASS/WARN/FAIL criteria, structured output template, <150 lines (move detail to `references/`)
- Agent definitions (`.md`): YAML frontmatter with `name` and `description`, role + decision guidelines + tool usage
- `plugin.json`: must include `name`, `version`, `description`, `author`. `skills`/`agents`/`hooks` are path strings or arrays of path strings (NOT object arrays). `displayName`/`category`/`tags` are NOT valid here — they go in `marketplace.json`
- `version` in `plugin.json` MUST match the corresponding entry in `marketplace.json`
- Reference docs go in `references/`, never inline in skill prompts
- Never commit secrets — use `${ENV_VAR}` placeholders in MCP configs

## Naming Conventions

- All directories and files: `kebab-case`
- Skill entrypoint: always `skill.md`
- Agent files: `<name>.md`
- Hook/script files: `<name>.sh`
- Meaningful exit codes for scripts: `0` ok, `1` issues found, `2` error

## Adding a New Skill

1. Create `plugins/<plugin>/skills/<skill-name>/skill.md` with YAML frontmatter
2. Add `references/` and `scripts/` subdirs only if needed
3. Ensure the plugin's `plugin.json` has `"skills": "./skills/"` pointing to the skills directory
4. If creating a new plugin, also register it in `.claude-plugin/marketplace.json`
5. If the skill should be available to Codex/Gemini/OpenCode, update the corresponding `INSTALL.md`

## Editing Skill Prompts

- Every check item must have explicit PASS/WARN/FAIL criteria
- Use the structured table output template (see `cicd-review/skill.md`)
- Keep prompts under 150 lines; move domain knowledge to `references/`
- Aim for 3–7 check categories with 2–6 checks per category

## Testing & Validation

```bash
# Validate a single plugin
claude plugin validate ./plugins/cicd-automation

# Validate ALL plugins
for dir in plugins/*/; do claude plugin validate "$dir"; done

# Dev mode: load and interactively test a plugin
claude --plugin-dir ./plugins/cicd-automation

# Standalone SHA pinning scanner
./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh

# Shellcheck all plugin scripts (CI does this too)
shellcheck -s bash -S warning $(find plugins -name '*.sh')

# Manual JSON validation
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"
```

## CI

`.github/workflows/validate-plugins.yml` runs on push/PR (paths: `.claude-plugin/**`, `plugins/**`) with 4 jobs:

1. **validate-json** — `marketplace.json` and every `plugin.json` have required fields
2. **validate-entrypoints** — every path referenced from a manifest resolves to a real file
3. **validate-scripts** — all `*.sh` are executable and pass shellcheck
4. **validate-consistency** — versions/names align between marketplace and plugin manifests; no orphaned plugins

All third-party actions in CI are SHA-pinned. Default permissions are `contents: read`.

## Commit & PR Style

- Use conventional prefixes: `feat:`, `fix:`, `chore:`, `refactor:`, `docs:`
- Keep subjects short and imperative
- Bump `version` in **both** `plugin.json` and `marketplace.json` together (semver: patch / minor / major)
- PR description should list the validation commands you ran and any sample prompts when behavior changes
