# Progressive disclosure patterns (detail)

## Three-tier load model

1. **Metadata only** at session start for all skills.
2. **SKILL.md body** when description matches.
3. **references/** only when the body explicitly directs a read.

## Pattern A — High-level guide + references

```markdown
# Foo Protocol

## Quick start
...

## Compartments
| Topic | Read when | File |
|-------|-----------|------|
| Architecture | Understanding system shape | [references/architecture.md](architecture.md) |
| User ops | Implementing calls | [references/operations.md](operations.md) |
| Risk params | Configuring markets | [references/risk.md](risk.md) |
```

## Pattern B — Multi-skill family (best for large docs)

Split into separately discoverable skills rather than one giant body:

| Skill | Owns |
|-------|------|
| `foo-architecture` | Contracts graph, storage, roles |
| `foo-operations` | User/admin call flows |
| `foo-deployment` | Addresses, init, upgrade |
| `foo-oracles` | Price feeds, staleness |

Shared “See also” links glue the family without forcing joint load.

## Pattern C — Conditional depth

Show basic path in SKILL.md; link advanced only when needed:

```markdown
**Simple path:** follow Quick start.
**Advanced hooks / custom curves:** see [references/advanced.md](advanced.md).
```

## Anti-pattern: deep nesting

```text
SKILL.md → advanced.md → details.md → more.md   # BAD
SKILL.md → advanced.md
SKILL.md → details.md                           # GOOD
```

## Reference file TOC template (&gt;100 lines)

```markdown
# Title

## Contents
- Section A
- Section B
- Section C

## Section A
...
```
