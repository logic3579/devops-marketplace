# Logic DevOps Marketplace: Gemini Context

This repository is a curated collection of DevOps-oriented plugins for AI assistants (Gemini CLI, Claude Code, OpenCode). It provides specialized skills and agents for CI/CD automation, infrastructure management, and security auditing.

## Project Overview

- **Purpose**: To provide reusable, high-quality DevOps automation capabilities to AI agents.
- **Architecture**: A modular marketplace where each plugin is a self-contained unit with its own manifest, skills, agents, and hooks.
- **Core Technologies**: Markdown (structured prompts), Bash (validation & automation), JSON (plugin manifests), and YAML (frontmatter & CI workflows).

### Directory Structure

- `.claude-plugin/`: Contains the global `marketplace.json` registry.
- `.mcp.json`: Project-scoped Model Context Protocol (MCP) server configurations (uses `${ENV_VAR}` placeholders).
- `.gemini/`: Gemini-specific installation and usage documentation (`INSTALL.md`).
- `.opencode/`: OpenCode-specific installation documentation.
- `plugins/`: The core of the repository, containing all available plugins.
    - `cicd-automation/`: CI/CD pipeline review and generation.
- `skills/`: Repo-level skills not packaged in any plugin (`changelog-generator`).
- `.github/workflows/`: Automated validation of plugin structure and JSON integrity.

## Shared MCP Servers

`.mcp.json` at the repo root provides 4 stdio MCP servers (auto-loaded by Claude Code from this directory). The same set is mirrored into `.codex/config.toml`, `.gemini/settings.json`, and `.opencode/opencode.json` — there is no auto-sync, so update all four files together when adding or removing a server.

| Server | Launcher | Purpose |
|---|---|---|
| `gcloud` | `npx @google-cloud/gcloud-mcp` | Google Cloud Platform |
| `kubernetes` | `npx kubernetes-mcp-server --read-only` | Kubernetes (read-only) |
| `grafana` | `mcp-grafana` (Go binary) | Grafana dashboards & datasources |
| `nightingale` | `npx @n9e/n9e-mcp-server` | Nightingale (n9e) monitoring |

Sensitive values use `${ENV_VAR}` placeholders. `grafana` and `nightingale` need one-time setup: install the binary (`go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest`) and export `GRAFANA_URL`, `GRAFANA_SERVICE_ACCOUNT_TOKEN`, `N9E_BASE_URL`, `N9E_TOKEN`. See `README.md` → "Setup Prerequisites" for full instructions.

## Development & Usage

### Key Commands

- **Installation (Gemini CLI)**:
  `gemini extensions install https://github.com/logic3579/devops-marketplace`
- **Update (Gemini CLI)**:
  `gemini extensions update devops-marketplace`
- **Validation**:
  `claude plugin validate ./plugins/<plugin-name>` (Requires Claude Code)
  `for dir in plugins/*/; do claude plugin validate "$dir"; done` (Validate all)
- **Interactive Testing (Dev Mode)**:
  `claude --plugin-dir ./plugins/<plugin-name>`
- **Standalone Scripts**:
  `./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh`

### Development Conventions

- **Naming**: Use `kebab-case` for all directories, files, and plugin/skill names.
- **Plugin Manifests**: Must include `name`, `version`, `description`, and `author`. `skills` and `agents` should point to directory paths or specific files.
- **Skill Entrypoints**: Always named `skill.md` within the skill's subdirectory.
- **Skill Structure**:
    - Must start with YAML frontmatter (`name`, `description`).
    - Define a clear role for the AI.
    - Use specific checklists with **PASS/WARN/FAIL** criteria.
    - Provide a structured output template (usually Markdown tables).
- **Domain Knowledge**: Move extensive reference materials to a `references/` subdirectory instead of inlining them in the prompt.
- **Shell Scripts**: 
    - Use `#!/usr/bin/env bash` and `set -euo pipefail`.
    - Must be executable (`chmod +x`).

## Adding a New Plugin/Skill

1.  **Scaffold**: Create the directory structure `plugins/<name>/{.claude-plugin,skills,agents,hooks}`.
2.  **Manifest**: Create `plugin.json` and register the plugin in `.claude-plugin/marketplace.json`.
3.  **Skill**: Create `skills/<skill-name>/skill.md` with proper frontmatter and instructions.
4.  **Validate**: Run the validation command to ensure the structure is correct.
5.  **Register**: Ensure the plugin is listed in the top-level `README.md` and marketplace registry.

## Security & Reliability

- **SHA Pinning**: All third-party actions and images must be pinned to a full commit SHA.
- **Least Privilege**: Default to read-only permissions; justify any write access.
- **Secrets**: Never hardcode secrets; use platform secret stores (e.g., GitHub Secrets).
- **Validation**: Every PR is automatically validated for JSON schema correctness and file path integrity via `.github/workflows/validate-plugins.yml`.
