# Inventory schema & clustering heuristics

## inventory.csv columns

```csv
id,url,title,section_path,parent_id,status,skill_targets,notes
1,https://docs.example.com/intro,Introduction,intro,,done,foo-architecture,
2,https://docs.example.com/swap,Swaps,guides/swap,,done,foo-operations,
```

`status`: `pending` | `done` | `failed` | `skipped_waived`

`skill_targets`: semicolon-separated skill names that will consume this page (may be multiple).

## Page note template

```markdown
# {title}

- source: {url}
- section: {section_path}
- fetched: {ISO-8601}

## Summary
…

## Concepts
- …

## APIs / contracts
- …

## Workflows
1. …

## Parameters / bounds
| Name | Meaning | Bounds |
|------|---------|--------|

## Warnings
- …

## Raw outline
- H2 …
  - H3 …
```

## Clustering heuristics

| Doc signal | Prefer skill |
|------------|--------------|
| “Overview”, “Architecture”, contract diagrams | `*-architecture` |
| “How to”, “Guide”, user actions | `*-operations` |
| “Deploy”, “Addresses”, “Configuration” | `*-deployment` |
| “Risk”, “Oracle”, “Liquidation”, “Security” | `*-risk` or split oracle |
| “SDK”, “API”, “TypeScript”, “Python” | `*-sdk` |
| “Governance”, “Timelock” | `*-governance` or fold into deployment |

If a page is pure glossary, attach terms to architecture or a small `*-glossary` reference under architecture—not a separate always-on skill unless huge.

## Completeness rule

A page is “mapped” only when:

1. It appears in inventory, and  
2. At least one skill’s SOURCES or family plan lists it, and  
3. Its unique actionable content appears in some `references/` or SKILL body (not just a link dump).
