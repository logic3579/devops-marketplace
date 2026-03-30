# Skill Quality Guidelines

Standards and patterns for writing high-quality skill prompts in the devops-marketplace.

## Anatomy of a Good Skill

A well-designed skill prompt has five sections in this order:

```
1. Role Definition     — WHO the skill is (one sentence)
2. Input Requirements  — WHAT it needs to operate
3. Procedure / Checks  — HOW it does the work (the core logic)
4. Output Format       — WHAT it produces (template)
5. References          — WHERE to find domain knowledge
```

## Prompt Quality Checklist

### Clarity
- [ ] Role definition is a single, unambiguous sentence
- [ ] No conflicting instructions
- [ ] Technical terms are used precisely (e.g., "SHA-pinned" not "version-locked")

### Completeness
- [ ] Every check has explicit PASS / WARN / FAIL criteria
- [ ] Output template covers all sections (summary, findings table, issues, recommendations)
- [ ] Edge cases are addressed (empty input, unsupported format, partial config)

### Consistency
- [ ] Check categories are logically grouped
- [ ] Severity levels (FAIL > WARN > PASS) are applied uniformly
- [ ] Output format matches between description and template

### Actionability
- [ ] Every FAIL includes a fix suggestion with code
- [ ] Every WARN includes an improvement suggestion
- [ ] Recommendations are concrete, not vague ("add timeout-minutes: 15" not "consider adding timeouts")

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| "Check for best practices" | Too vague — output varies per invocation | Enumerate each practice as a named check |
| Inlining 200+ lines of rules | Prompt becomes noisy, hard to maintain | Move rules to `references/` files |
| No output template | Claude invents a different format each time | Provide a concrete markdown template |
| "Be thorough" | Means nothing actionable | Replace with specific check items |
| Mixing review + fix | Scope creep — skill tries to do everything | Split into two skills (review + fix) |

## Sizing Guidelines

| Skill Component | Target Size | Rationale |
|-----------------|-------------|-----------|
| `skill.md` | 50–150 lines | Enough for role + checks + output format; longer = move to references |
| Individual reference file | 50–200 lines | Focused on one topic; split if exceeding 200 lines |
| Script | < 100 lines | Single-purpose; compose multiple small scripts over one large one |
| Check categories | 3–7 per skill | Fewer = skill too narrow; more = consider splitting |
| Checks per category | 2–6 | Enough to be thorough without being exhausting |

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Skill directory | `kebab-case`, verb-noun or noun | `cicd-review`, `pipeline-generator` |
| Skill prompt | Always `skill.md` | `skill.md` |
| Reference files | `kebab-case`, descriptive | `github-actions-best-practices.md` |
| Scripts | `kebab-case`, verb-noun | `check-sha-pinning.sh` |

## Reference Document Standards

Good reference documents:

- **Focus on one topic** — "GitHub Actions Security" not "Everything About CI/CD"
- **Use tables for lookup data** — pricing, version matrices, rule sets
- **Include code examples** — show both the bad pattern and the fix
- **Cite sources** — link to official docs, RFCs, or CVE databases
- **Stay evergreen** — avoid version-specific content that goes stale quickly; if unavoidable, note the date
