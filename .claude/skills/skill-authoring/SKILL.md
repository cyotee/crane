---
name: skill-authoring
description: This skill should be used when the user asks to "write a skill", "author SKILL.md", "skill best practices", "progressive disclosure", "skill structure", "skill description triggers", "compartment skills", "references folder for skills", "how to write effective agent skills", or needs guidance on structuring skills for efficient on-demand reading.
license: MIT
---

# Skill Authoring Best Practices

How to write agent skills that **discover reliably**, **load only what is needed**, and **stay accurate**. Grounded in Anthropic’s progressive-disclosure model and Crane/OpenCode conventions. Use with `docs-to-skills` when generating skills from documentation sites.

## Progressive disclosure (the core design)

Skills load in tiers so context stays lean:

| Tier | What loads | When | Budget guidance |
|------|------------|------|-----------------|
| **1 — Metadata** | `name` + `description` from every installed skill | Session start (always) | ~100 tokens per skill |
| **2 — Body** | Full `SKILL.md` | When description matches the task | Prefer **&lt;200 lines**; hard target **&lt;500 lines** |
| **3 — References** | Files under `references/`, scripts, examples | Only when the body points agent to them | No cost until read |

**Implication:** `SKILL.md` is a **table of contents + procedures**, not an encyclopedia. Detail lives one level deep in `references/*.md`.

## Directory layout (compartmentalized)

```text
skill-name/
├── SKILL.md                 # Required: frontmatter + lean body + nav to references
├── references/              # Optional: domain slices loaded on demand
│   ├── overview.md
│   ├── api-surface.md
│   ├── workflows.md
│   └── gotchas.md
├── scripts/                 # Optional: deterministic helpers (run, don’t paste)
└── assets/                  # Optional: templates, diagrams
```

### Multi-skill families (preferred for large docs)

Split by **task domain**, not by dumping one mega-skill:

```text
foo-architecture/     # "how Foo works"
foo-operations/       # "how to swap/supply/claim"
foo-deployment/       # "how to deploy/configure"
foo-security/         # "threats, params, limits"
```

Each skill has its own description triggers so only the relevant compartment activates.

## Frontmatter rules

```yaml
---
name: skill-name          # lowercase, hyphens, max 64 chars; match directory name
description: >-           # max 1024 chars; third person; WHAT + WHEN + key terms
  ...
license: MIT              # optional
---
```

### Description formula (critical for discovery)

**[What it does] + [When to use it, with trigger phrases] + [Key terms / file types / protocol names]**

- Write in **third person** (“Extracts…”, “Guides…”) — not “I can help” or “You can use”.
- Prefer under-trigger fixes: Claude often **under-triggers**; put all “when to use” in `description`, not only in the body.
- Include **quoted-style natural phrases** users type: `"deploy Foo"`, `"swap on Bar"`, `"VaultSwapParams"`.
- Include **DO NOT** exclusions when another skill owns the domain (optional but reduces fights).

**Good:**

```yaml
description: Guides Uniswap V4 swap execution (exactInput, flash accounting, hooks). Use when the user asks about "V4 swap", "SwapParams", "beforeSwap", or building swap flows on PoolManager.
```

**Bad:**

```yaml
description: Helps with Uniswap
```

## SKILL.md body structure

Recommended sections (keep lean):

1. **One-line purpose**
2. **When / when not** (brief; full triggers live in description)
3. **Quick start** (smallest useful procedure or example)
4. **Navigation table** → `references/*` (one level deep only)
5. **Constraints / gotchas** (bullets)
6. **Key files** (real repo paths when applicable)
7. **See also** (`skill:other-name`, related agents)

### Reference files (compartment rules)

| Rule | Why |
|------|-----|
| Link **only one level deep** from `SKILL.md` | Nested refs (A→B→C) cause partial reads |
| `references/` files **&gt;100 lines** start with a **Contents** TOC | Agents previewing with `head` still see the map |
| One concern per file | e.g. `liquidation.md` separate from `interest-rates.md` |
| Descriptive names | `swap-exact-input.md`, not `doc2.md` |
| Forward slashes only | `references/foo.md`, never Windows `\` |
| Consistent terminology | One term for each concept across the family |

## Content guidelines

### Concise is key

- Context is shared with system prompt, history, and other skills.
- Assume the model is smart: **do not** re-teach general programming/Solidity basics.
- Challenge every paragraph: “Does this justify its tokens?”

### Degrees of freedom

| Freedom | When | Form |
|---------|------|------|
| **High** | Many valid approaches | Heuristics, checklists |
| **Medium** | Preferred pattern exists | Templates with parameters |
| **Low** | Fragile / security / deploy | Exact commands, fixed sequences |

Match freedom to risk: migrations and fund-moving steps → **low freedom**.

### Workflows and feedback loops

For multi-step work, give a **copyable checklist** and explicit **validate → fix → re-validate** loops. Critical ops need a verification step before “done.”

### Examples over abstract prose

Prefer input/output pairs, tables, and real signatures over long narrative.

### Avoid

- Time-sensitive “before date X” without a dated “legacy” section
- Offering five libraries with no default
- Windows paths
- Magic constants without justification
- Mega-skills that force full-doc load for a one-function question
- Putting “when to use” only in the body (missed discovery)

## Crane-specific conventions

When authoring skills for this monorepo family (Crane / IndexedEx):

- Prefer install path: `.claude/skills/<name>/SKILL.md` (also mirrored for `.agents/` / `.grok/` when present).
- Use **`@crane/`** import paths in Solidity examples.
- Anchor to **real files** under `contracts/` and `test/`.
- Cross-link `skill:crane-*` and protocol skills.
- After porting a protocol, ship a **skill family** (architecture + operations), not one 2k-line file — see `writing-skills` and exemplar Aave/Uniswap skill sets.
- Production-first testing guidance belongs in `crane-testing`, not duplicated in every protocol skill.

## Quality checklist (before shipping a skill)

- [ ] `name` matches directory; description is third-person, WHAT+WHEN, &lt;1024 chars
- [ ] Description includes concrete trigger terms; not vague (“helps with X”)
- [ ] `SKILL.md` body ideally &lt;200 lines, always &lt;500
- [ ] Heavy detail in `references/` with TOC if long
- [ ] All reference links are one level deep from `SKILL.md`
- [ ] Consistent terminology; default tool/library chosen
- [ ] Gotchas and constraints explicit
- [ ] See also / related skills listed
- [ ] For protocol skills: paths and selectors verified against code when code exists
- [ ] Smoke-test: does a fresh agent load this skill on three representative prompts?

## See also

- `skill:docs-to-skills` — scrape full documentation sites and emit skill families
- `skill:writing-skills` — OpenCode/Crane-oriented skill writing (legacy companion)
- Anthropic: [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- Agent: `docs-skill-scribe`
