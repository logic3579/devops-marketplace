# Installing DevOps Marketplace for Codex

Enable DevOps Marketplace skills in Codex via native skill discovery.

This installation flow follows the same Codex pattern used by the official `superpowers` plugin: clone the repository locally, expose skills through `~/.agents/skills/`, then restart Codex.

## Prerequisites

- Git

## Installation

1. **Clone the repository into `~/.codex`:**

```bash
git clone https://github.com/logic3579/devops-marketplace.git ~/.codex/devops-marketplace
```

2. **Create Codex skill links:**

Codex discovers skills from `~/.agents/skills/<skill-name>/SKILL.md`.

This repository is organized as a plugin marketplace, so the Codex install step creates small compatibility directories that point to the real skill sources in the repo.

```bash
mkdir -p ~/.agents/skills

# cicd-review
mkdir -p ~/.agents/skills/cicd-review
ln -s ~/.codex/devops-marketplace/plugins/cicd-automation/skills/cicd-review/skill.md ~/.agents/skills/cicd-review/SKILL.md
ln -s ~/.codex/devops-marketplace/plugins/cicd-automation/skills/cicd-review/references ~/.agents/skills/cicd-review/references
ln -s ~/.codex/devops-marketplace/plugins/cicd-automation/skills/cicd-review/scripts ~/.agents/skills/cicd-review/scripts

# pipeline-generator
mkdir -p ~/.agents/skills/pipeline-generator
ln -s ~/.codex/devops-marketplace/plugins/cicd-automation/skills/pipeline-generator/skill.md ~/.agents/skills/pipeline-generator/SKILL.md

# skill-creator
mkdir -p ~/.agents/skills/skill-creator
ln -s ~/.codex/devops-marketplace/plugins/marketplace-tools/skills/skill-creator/skill.md ~/.agents/skills/skill-creator/SKILL.md
ln -s ~/.codex/devops-marketplace/plugins/marketplace-tools/skills/skill-creator/references ~/.agents/skills/skill-creator/references
```

3. **Restart Codex** so it re-discovers installed skills.

## Available Skills

After installation, Codex should be able to discover these skills:

- `cicd-review`: Review GitHub Actions or GitLab CI pipelines for security, reliability, performance, and compliance issues.
- `pipeline-generator`: Generate CI/CD pipelines with safer defaults.
- `skill-creator`: Scaffold new marketplace skills and supporting files.

## Notes

- This installs Codex-compatible skills only.
- Claude-specific marketplace metadata, agents, and hooks in this repository are not loaded directly by Codex.
- The symlinked setup means edits inside `~/.codex/devops-marketplace` are reflected immediately in Codex after restart.

## Verify

```bash
ls -la ~/.agents/skills/cicd-review
ls -la ~/.agents/skills/pipeline-generator
ls -la ~/.agents/skills/skill-creator
```

You should see `SKILL.md` symlinks pointing back to the cloned repository.

Then start a new Codex session and ask for a task that should match one of the installed skills, for example:

- "Review this GitHub Actions workflow for security issues."
- "Generate a GitHub Actions pipeline for this project."
- "Create a new marketplace skill for Terraform review."

## Updating

```bash
cd ~/.codex/devops-marketplace && git pull
```

The skill links continue to point at the updated files.

## Uninstalling

```bash
rm -rf ~/.agents/skills/cicd-review
rm -rf ~/.agents/skills/pipeline-generator
rm -rf ~/.agents/skills/skill-creator
```

Optionally remove the clone:

```bash
rm -rf ~/.codex/devops-marketplace
```
