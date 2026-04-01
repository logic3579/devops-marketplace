# Logic DevOps Marketplace

A curated collection of DevOps-oriented Claude Code plugins for CI/CD automation, infrastructure management, and deployment workflows. Designed for personal and team use.

## Architecture

```
devops-marketplace/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace registry — lists all plugins
├── plugins/
│   └── <plugin-name>/
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin manifest — skills, agents, hooks
│       ├── skills/
│       │   └── <skill-name>/
│       │       ├── skill.md      # Skill prompt (entrypoint)
│       │       ├── references/   # Knowledge base for the skill
│       │       └── scripts/      # Supporting scripts
│       ├── agents/
│       │   └── <agent-name>.md   # Agent definition
│       └── hooks/
│           └── <hook-name>.sh    # Hook scripts
└── README.md
```

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Marketplace** | Top-level registry (`marketplace.json`) that indexes all available plugins |
| **Plugin** | A self-contained capability package with its own manifest (`plugin.json`) |
| **Skill** | A prompt-driven capability that Claude Code can invoke — typically a `.md` file with structured instructions, checklists, or templates |
| **Agent** | A multi-step autonomous workflow definition, combining multiple skills and tools |
| **Hook** | A shell script triggered by events (e.g. pre-commit) to enforce standards automatically |
| **Reference** | Domain knowledge documents that skills and agents consult during execution |

### Data Flow

```
User Request
  └─> Marketplace (plugin.json trigger matching)
        └─> Skill / Agent
              ├─> References (knowledge base)
              ├─> Scripts (validation tools)
              └─> Claude Code tools (Read, Edit, Grep, Bash...)
```

## Available Plugins

### cicd-automation `v1.0.0`

Review and generate CI/CD pipelines (GitHub Actions, GitLab CI) with security-first defaults.

| Component | Name | Description |
|-----------|------|-------------|
| Skill | `cicd-review` | Audits pipelines against 15+ checks across security, reliability, performance, maintainability, and compliance |
| Skill | `pipeline-generator` | Generates production-ready pipelines with SHA-pinned actions, least-privilege permissions, caching, and timeouts |
| Agent | `cicd-agent` | Full-lifecycle agent: review, generate, diagnose failures, and apply fixes |
| Hook | `workflow-lint` | Pre-commit hook validating YAML syntax, SHA pinning, and required fields |
| Script | `check-sha-pinning` | Standalone scanner for unpinned third-party actions |

### share-mcp

Shared MCP server configurations for team collaboration. Provides a `.mcp.json` with pre-configured servers using `npx`/`uvx` launchers and environment variable placeholders for sensitive data.

| Server | Launcher | Description |
|--------|----------|-------------|
| `github` | npx | GitHub API via `@modelcontextprotocol/server-github` |
| `sentry` | npx | Sentry error tracking via `@sentry/mcp-server` |
| `gcloud` | npx | Google Cloud Platform via `@google-cloud/gcloud-mcp` |
| `kubernetes` | npx | Kubernetes cluster management via `kubernetes-mcp-server` (read-only) |
| `clickhouse` | npx | ClickHouse database via `@anthropic/mcp-server-clickhouse` |
| `mysql` | uvx | MySQL database via `mcp-server-mysql` |
| `postgres` | npx | PostgreSQL via `@modelcontextprotocol/server-postgres` |
| `slack` | npx | Slack messaging via `@modelcontextprotocol/server-slack` |
| `linear` | npx | Linear project management via `mcp-linear` |
| `grafana` | npx | Grafana dashboards via `@grafana/mcp-server` |
| `filesystem` | npx | Local filesystem access via `@modelcontextprotocol/server-filesystem` |

## Getting Started

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Git

### Installation

Clone the marketplace into your projects directory:

```bash
git clone https://github.com/logic/devops-marketplace.git
cd devops-marketplace
```

### Validate a Plugin

Before installing or sharing, validate that a plugin's structure is correct:

```bash
claude plugin validate ./plugins/cicd-automation
```

This checks:
- `plugin.json` is valid and has all required fields
- All `entrypoint` paths resolve to existing files
- Scripts are executable
- No obvious issues in skill prompts

### Install & Use — Three Modes

#### Mode 1: Dev Mode (single plugin, quick iteration)

Load a plugin directory directly into Claude Code for immediate testing. Changes to `skill.md` take effect on the next invocation — no reinstall needed.

```bash
# Launch Claude Code with the plugin loaded
claude --plugin-dir ./plugins/cicd-automation

# Inside Claude Code, list available skills
/skills

# Invoke skills directly
/cicd-review
/pipeline-generator github-actions
```

This is the fastest feedback loop for developing and debugging skills.

#### Mode 2: Marketplace Registration (full marketplace, team sharing)

Register the entire marketplace so all plugins are available. Best for team-wide distribution — every member points to the same marketplace path or repo.

```bash
# Register the marketplace (absolute path or git URL)
/plugin marketplace add /absolute/path/to/devops-marketplace

# Install a specific plugin from the marketplace
/plugin install cicd-automation@devops-marketplace

# Verify installed skills
/skills
```

To share with team members:

```bash
# Team member clones the marketplace repo
git clone https://github.com/logic/devops-marketplace.git

# Register their local copy
/plugin marketplace add /absolute/path/to/devops-marketplace

# Install any plugin
/plugin install cicd-automation@devops-marketplace
/plugin install marketplace-tools@devops-marketplace
```

#### Mode 3: Project-Embedded (per-project integration)

Embed plugins directly into a target project so they are available to anyone who clones it.

**Option A: Symlink** (recommended for local development)

```bash
# From your target project root
ln -s /path/to/devops-marketplace/plugins/cicd-automation .claude/plugins/cicd-automation
```

**Option B: Copy**

```bash
cp -r /path/to/devops-marketplace/plugins/cicd-automation .claude/plugins/cicd-automation
```

**Option C: Git submodule**

```bash
git submodule add https://github.com/logic/devops-marketplace.git .claude/marketplace
```

### Using the Pre-commit Hook

To enable the workflow lint hook in your target project:

```bash
# Copy or symlink the hook
cp /path/to/devops-marketplace/plugins/cicd-automation/hooks/workflow-lint.sh \
   .git/hooks/pre-commit

# Or add to an existing pre-commit framework (e.g. pre-commit)
# See: https://pre-commit.com
```

### Running Scripts Standalone

The SHA pinning checker can run independently:

```bash
# Check default .github/workflows/ directory
./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh

# Check a specific directory
./plugins/cicd-automation/skills/cicd-review/scripts/check-sha-pinning.sh /path/to/project/.github/workflows
```

## Team Validation

### Validating the Marketplace Structure

Verify that all plugin manifests are well-formed and referenced correctly:

```bash
# Validate a single plugin
claude plugin validate ./plugins/cicd-automation

# Validate all plugins in the marketplace
for dir in plugins/*/; do
  echo "=== $(basename "$dir") ==="
  claude plugin validate "$dir"
done
```

Or manually check with scripts:

```bash
# Check marketplace.json is valid JSON
python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"

# Check all plugin.json files
find plugins -name 'plugin.json' -exec sh -c \
  'echo "Checking: $1" && python3 -c "import json; json.load(open(\"$1\"))"' _ {} \;

# Verify all entrypoints exist
python3 -c "
import json, os
for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']:
    src = p['source']
    manifest = json.load(open(f\"{src}/.claude-plugin/plugin.json\"))
    for s in manifest.get('skills', []):
        ep = os.path.join(src, s['entrypoint'])
        status = 'OK' if os.path.exists(ep) else 'MISSING'
        print(f'  [{status}] {s[\"name\"]}: {ep}')
    for a in manifest.get('agents', []):
        ep = os.path.join(src, a['entrypoint'])
        status = 'OK' if os.path.exists(ep) else 'MISSING'
        print(f'  [{status}] {a[\"name\"]}: {ep}')
    for h in manifest.get('hooks', []):
        ep = os.path.join(src, h['entrypoint'])
        status = 'OK' if os.path.exists(ep) else 'MISSING'
        print(f'  [{status}] {h[\"name\"]}: {ep}')
"
```

### Testing Skills End-to-End

```bash
# Dev mode: load plugin and test interactively
claude --plugin-dir ./plugins/cicd-automation

# Inside Claude Code:
/skills                            # List all available skills
/cicd-review                       # Run review on current project's workflows
/pipeline-generator github-actions  # Generate a GitHub Actions pipeline

# One-shot test from CLI
claude "Review the CI/CD pipeline in .github/workflows/ci.yml"
claude "Generate a GitHub Actions CI pipeline for this Node.js project"
```

### Peer Review Checklist

When reviewing plugin contributions from team members:

- [ ] `claude plugin validate ./plugins/<name>` passes
- [ ] `plugin.json` is valid JSON with all required fields
- [ ] All `entrypoint` paths resolve to existing files
- [ ] Skill prompts have clear trigger descriptions
- [ ] Reference documents are accurate and up-to-date
- [ ] Scripts are executable (`chmod +x`) and have usage comments
- [ ] Scripts use `set -euo pipefail` for safety
- [ ] No hardcoded paths or credentials
- [ ] Version in `plugin.json` matches `marketplace.json`

## Development

### Adding a New Plugin

1. Create the plugin directory structure:

```bash
mkdir -p plugins/<plugin-name>/{.claude-plugin,skills,agents,hooks}
```

2. Create the plugin manifest at `plugins/<plugin-name>/.claude-plugin/plugin.json`:

```json
{
  "name": "<plugin-name>",
  "displayName": "<Plugin Display Name>",
  "version": "1.0.0",
  "description": "<What the plugin does>",
  "category": "devops",
  "tags": ["<tag1>", "<tag2>"],
  "skills": [],
  "agents": [],
  "hooks": []
}
```

3. Register the plugin in `.claude-plugin/marketplace.json` under the `plugins` array.

### Adding a New Skill

1. Create the skill directory:

```bash
mkdir -p plugins/<plugin-name>/skills/<skill-name>/{references,scripts}
```

2. Write the skill prompt in `skill.md` — this is the core instruction set that Claude follows. Structure it with:
   - YAML frontmatter with `name` and `description` fields
   - A clear role definition (first line after frontmatter)
   - Input requirements (what the skill needs to operate)
   - Step-by-step checklist or procedure
   - Output format specification
   - Reference to supporting documents

3. Add reference documents and scripts as needed.

4. Register the skill in the plugin's `plugin.json`.

### Writing Effective Skill Prompts

Tips for writing skills that produce consistent, high-quality results:

- **Be specific about output format** — use tables, templates, or examples so Claude knows exactly what to produce
- **Use checklists** — enumerated checks are more reliable than vague instructions like "review for best practices"
- **Include pass/fail criteria** — define what PASS, WARN, and FAIL mean for each check
- **Reference external knowledge** — put domain knowledge in `references/` files rather than inlining everything in the prompt
- **Test with edge cases** — try the skill against minimal, complex, and intentionally broken inputs

### Iterating on Skills

The fastest feedback loop for developing skills:

```bash
# 1. Edit the skill prompt
#    (modify plugins/<plugin>/skills/<skill>/skill.md)

# 2. Test it immediately in Claude Code
claude "Review this workflow: $(cat .github/workflows/ci.yml)"

# 3. Compare output against your expectations
# 4. Refine the prompt and repeat
```

For systematic iteration:

1. Create a `tests/` directory with sample inputs (good and bad pipeline files)
2. Run the skill against each sample
3. Check that findings match expected results
4. Adjust the prompt until all samples produce correct output

### Versioning

- Bump `version` in both `plugin.json` and `marketplace.json` when making changes
- Use semver: patch for fixes, minor for new skills/features, major for breaking changes

## License

MIT
