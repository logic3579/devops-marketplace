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
├── skills/                       # Repo-level skills (not packaged in any plugin)
│   └── <skill-name>/
│       ├── skill.md
│       └── references/
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

## Repo-Level Skills

Standalone skills under `skills/` that are not bundled into any plugin. Use them directly in dev mode or symlink/copy into your tool of choice.

| Skill | Description |
|-------|-------------|
| `changelog-generator` | Generate user-facing changelogs from git commits by analyzing history, categorizing changes, and rewriting commits as release notes |

## Shared MCP Servers

A project-scoped `.mcp.json` at the repo root provides 4 stdio MCP servers. Claude Code loads them automatically when launched from this directory. Sensitive values use `${ENV_VAR}` placeholders so secrets never land in git.

| Server | Launcher | Description | Setup |
|--------|----------|-------------|-------|
| `gcloud` | `npx @google-cloud/gcloud-mcp` | Google Cloud Platform | — |
| `kubernetes` | `npx kubernetes-mcp-server --read-only` | Kubernetes cluster (read-only) | — |
| `grafana` | `mcp-grafana` (Go binary) | Grafana dashboards & datasources | Binary + env vars |
| `nightingale` | `npx @n9e/n9e-mcp-server` | Nightingale (n9e) monitoring | Env vars |

### Setup Prerequisites

`gcloud` and `kubernetes` work out of the box (assuming `npx` and your local `gcloud` / `kubectl` configs are present). The other two need a one-time setup.

**1. Install the `mcp-grafana` binary** — required for the `grafana` server

The `grafana` entry invokes a locally-installed Go binary instead of going through `npx`:

```bash
go install github.com/grafana/mcp-grafana/cmd/mcp-grafana@latest
```

Make sure `$(go env GOPATH)/bin` is on your `$PATH` so Claude Code can resolve `mcp-grafana`.

**2. Export environment variables** — required for `grafana` and `nightingale`

Both servers read credentials from the environment. Add the following to your shell profile (`~/.zshrc`, `~/.bashrc`, or a per-directory loader like [direnv](https://direnv.net/)):

```bash
# Grafana
export GRAFANA_URL="https://grafana.example.com"
export GRAFANA_SERVICE_ACCOUNT_TOKEN="<your-grafana-service-account-token>"

# Nightingale (n9e)
export N9E_BASE_URL="https://nightingale.example.com"
export N9E_TOKEN="<your-nightingale-api-token>"
```

Replace the placeholders with your real values. `.mcp.json` references them by name only (`${GRAFANA_URL}` etc.), so credentials stay out of the repo.

> Launch Claude Code from a shell where these variables are already exported — child processes inherit the environment, so unset variables = silent server startup failure.

## Getting Started

### Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Git

### Installation

Clone the marketplace into your projects directory:

```bash
git clone https://github.com/logic3579/devops-marketplace.git
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
git clone https://github.com/logic3579/devops-marketplace.git

# Register their local copy
/plugin marketplace add /absolute/path/to/devops-marketplace

# Install any plugin
/plugin install cicd-automation@devops-marketplace
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
git submodule add https://github.com/logic3579/devops-marketplace.git .claude/marketplace
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

# Validate all plugins
for dir in plugins/*/; do
  echo "=== $(basename "$dir") ==="
  claude plugin validate "$dir"
done
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
- [ ] `plugin.json` is valid JSON with correct schema (`skills`/`agents` as path strings, no `displayName`)
- [ ] Skill/agent `.md` files have YAML frontmatter with `name` and `description`
- [ ] Reference documents are accurate and up-to-date
- [ ] Scripts are executable (`chmod +x`) and have usage comments
- [ ] Scripts use `set -euo pipefail` for safety
- [ ] No hardcoded paths or credentials
- [ ] `plugin.json` includes `author` field
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
  "version": "1.0.0",
  "description": "<What the plugin does>",
  "author": { "name": "logic" },
  "skills": "./skills/",
  "agents": "./agents/"
}
```

> **Note:** `displayName`, `category`, and `tags` are NOT valid in `plugin.json`. Use `marketplace.json` for category/tags. `skills`/`agents` must be path strings or arrays of path strings, not object arrays.

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

4. Ensure the plugin's `plugin.json` has `"skills": "./skills/"` pointing to the skills directory.

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
