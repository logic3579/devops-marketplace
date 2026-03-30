# Marketplace Conventions

Structural rules and conventions for the devops-marketplace that the skill-creator must follow when scaffolding.

## Directory Layout

Every plugin MUST follow this structure:

```
plugins/<plugin-name>/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest (required)
├── skills/
│   └── <skill-name>/
│       ├── skill.md           # Skill entrypoint (required)
│       ├── references/        # Knowledge base (optional)
│       └── scripts/           # Shell scripts (optional)
├── agents/
│   └── <agent-name>.md       # Agent definitions (optional)
└── hooks/
    └── <hook-name>.sh        # Hook scripts (optional)
```

## plugin.json Schema

```json
{
  "name": "string (required) — kebab-case, matches directory name",
  "displayName": "string (required) — human-readable name",
  "version": "string (required) — semver (e.g., 1.0.0)",
  "description": "string (required) — what the plugin does",
  "category": "string (required) — e.g., devops, tooling, security",
  "tags": ["array of strings (required) — searchable keywords"],
  "skills": [
    {
      "name": "string — kebab-case skill identifier",
      "displayName": "string — human-readable name",
      "trigger": "string — when this skill should be invoked",
      "entrypoint": "string — relative path from plugin root to skill.md"
    }
  ],
  "agents": [
    {
      "name": "string — kebab-case agent identifier",
      "displayName": "string — human-readable name",
      "description": "string — what the agent does",
      "entrypoint": "string — relative path to agent .md file"
    }
  ],
  "hooks": [
    {
      "name": "string — kebab-case hook identifier",
      "event": "string — trigger event (e.g., pre-commit)",
      "description": "string — what the hook checks",
      "entrypoint": "string — relative path to hook .sh file"
    }
  ]
}
```

## marketplace.json Registration

When creating a new plugin, it must also be registered in `.claude-plugin/marketplace.json`:

```json
{
  "name": "<plugin-name>",
  "description": "<plugin description>",
  "version": "<same version as plugin.json>",
  "source": "./plugins/<plugin-name>",
  "category": "<category>",
  "tags": ["<tag1>", "<tag2>"]
}
```

## Versioning Rules

- `version` in `marketplace.json` and `plugin.json` MUST match for the same plugin
- Use semver: `MAJOR.MINOR.PATCH`
  - PATCH: fix typos, adjust prompt wording, update references
  - MINOR: add new skills/agents/hooks to existing plugin
  - MAJOR: restructure plugin, remove or rename skills, change output format

## File Naming Rules

| Type | Naming | Example |
|------|--------|---------|
| Plugin directory | `kebab-case` | `cicd-automation` |
| Skill directory | `kebab-case` | `pipeline-generator` |
| Skill entrypoint | Always `skill.md` | `skill.md` |
| Agent file | `kebab-case.md` | `cicd-agent.md` |
| Hook file | `kebab-case.sh` | `workflow-lint.sh` |
| Reference file | `kebab-case.md` | `security-checklist.md` |
| Script file | `kebab-case.sh` | `check-sha-pinning.sh` |
