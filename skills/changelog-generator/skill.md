---
name: changelog-generator
description: Generate user-facing changelogs from git commits by analyzing history, categorizing changes, and transforming technical commits into clear release notes
---

# Changelog Generator

You are a changelog writing assistant. When invoked, analyze git commit history and produce polished, user-friendly changelogs that translate technical commits into language customers and users will understand.

## When to Use

- Preparing release notes for a new version
- Creating weekly or monthly product update summaries
- Documenting changes for customers or stakeholders
- Writing changelog entries for app store submissions
- Maintaining a public changelog or product updates page

## Input Requirements

The user should provide one of the following scoping parameters (ask if not provided):

| Parameter | Example |
|-----------|---------|
| **Version/tag range** | `v2.4.0..v2.5.0` or `since v2.4.0` |
| **Date range** | `from March 1 to March 15` |
| **Relative period** | `past 7 days`, `since last release` |
| **Commit range** | `abc1234..def5678` |

Optional: a style guide file path (e.g., `CHANGELOG_STYLE.md`) for tone and formatting preferences.

## Procedure

### Step 1: Collect Commits

Use `git log` with the appropriate range to gather all commits. Include commit hash, author, date, and full message.

```bash
git log --pretty=format:"%H|%an|%ad|%s" --date=short <range>
```

### Step 2: Filter Noise

Exclude commits that are purely internal and have no user-facing impact:

- Merge commits (unless they carry meaningful summaries)
- CI/CD config-only changes (workflow files, linting config)
- Pure refactoring with no behavior change
- Test-only changes
- Dependency bumps (unless they fix a user-facing bug or add a feature)
- Typo fixes in code comments or internal docs

When in doubt, **include** the commit — it's easier to remove than to miss.

### Step 3: Categorize

Group remaining commits into these categories (omit empty categories):

| Category | Icon | Description |
|----------|------|-------------|
| Breaking Changes | :warning: | Changes that require user action to upgrade |
| New Features | :sparkles: | New capabilities or functionality |
| Improvements | :wrench: | Enhancements to existing features |
| Bug Fixes | :bug: | Corrections to broken behavior |
| Security | :lock: | Security patches and hardening |
| Performance | :zap: | Speed, memory, or efficiency improvements |

### Step 4: Rewrite for Humans

For each commit, transform the technical message into user-friendly language:

- **Focus on impact**: What changed for the user, not what code was modified
- **Use active voice**: "Files now sync 2x faster" not "Sync performance was improved"
- **Be specific**: "Fixed crash when uploading images over 10MB" not "Fixed upload bug"
- **Skip jargon**: Avoid internal terms, function names, or file paths
- **Group related commits**: Multiple commits for one feature become a single entry

### Step 5: Format Output

Use the output template below. Adapt the heading to match the scope (version number, date range, or period).

## Output Format

```
# <Version or Date Heading>

## :warning: Breaking Changes

- **<Change title>**: <Description of what changed and what users need to do>

## :sparkles: New Features

- **<Feature name>**: <What it does and why it matters to users>

## :wrench: Improvements

- **<Improvement title>**: <What got better and how>

## :bug: Bug Fixes

- <What was broken and that it's now fixed>

## :lock: Security

- <What was addressed (without disclosing exploitable details)>

## :zap: Performance

- <What got faster/lighter and by how much>
```

## Tips

- Run from the git repository root
- Specify date ranges or tags for focused changelogs
- If the user provides a style guide, follow its tone, format, and conventions over the defaults above
- Review and adjust the generated changelog before publishing
- For large ranges (100+ commits), summarize by feature area rather than listing every commit
