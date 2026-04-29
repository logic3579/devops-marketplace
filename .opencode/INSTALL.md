# DevOps Marketplace for OpenCode

Complete guide for using the Logic DevOps Marketplace with [OpenCode.ai](https://opencode.ai).

## Installation

Add the marketplace to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["devops-marketplace@git+https://github.com/logic3579/devops-marketplace.git"]
}
```

Restart OpenCode. The plugin auto-installs via Bun and registers all skills automatically.

Verify by asking: "Tell me about your devops skills"

### Installing a Specific Plugin

To install only a specific plugin (e.g., `cicd-automation`):

```json
{
  "plugin": ["cicd-automation@git+https://github.com/logic3579/devops-marketplace.git#plugins/cicd-automation"]
}
```

## Available Plugins

### cicd-automation

Review and generate CI/CD pipelines (GitHub Actions, GitLab CI). Checks security, SHA pinning, supply chain, permissions, caching, and compliance.

**Skills:**
- `cicd-review` - Review existing CI/CD pipeline files for security and best practices
- `cicd-generate` - Generate new GitHub Actions or GitLab CI pipelines

### Repo-Level Skills

Standalone skills under `skills/` that are not packaged into any plugin:

- `skill-creator` - Generate new skills with proper YAML frontmatter and structure
- `changelog-generator` - Generate user-facing changelogs from git commit history

### Shared MCP Servers

A project-scoped `.mcp.json` at the repo root provides shared MCP server configurations for team collaboration (GitHub, Sentry, GCloud, Kubernetes, ClickHouse, MySQL, Postgres, Slack, Linear, Grafana, Filesystem).

## Usage

### Finding Skills

Use OpenCode's native `skill` tool to list all available skills:

```
use skill tool to list skills
```

### Loading a Skill

```
use skill tool to load cicd-automation/cicd-review
```

### Project Skills

Create project-specific skills in `.opencode/skills/` within your project.

**Skill Priority:** Project skills > Marketplace skills

## Updating

The marketplace updates automatically when you restart OpenCode. The plugin is re-installed from the git repository on each launch.

To pin a specific version, use a branch or tag:

```json
{
  "plugin": ["devops-marketplace@git+https://github.com/logic3579/devops-marketplace.git#v1.0.0"]
}
```

## Troubleshooting

### Plugin not loading

1. Check OpenCode logs: `opencode run --print-logs "hello" 2>&1 | grep -i devops`
2. Verify the plugin line in your `opencode.json` is correct
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use OpenCode's `skill` tool to list available skills
2. Check that the plugin is loading (see above)
3. Each skill needs a `skill.md` file with valid YAML frontmatter

## Getting Help

- Report issues: [https://github.com/logic3579/devops-marketplace/issues](https://github.com/logic3579/devops-marketplace/issues)
- Main repository: [https://github.com/logic3579/devops-marketplace](https://github.com/logic3579/devops-marketplace)
- OpenCode docs: [https://opencode.ai/docs/](https://opencode.ai/docs/)
