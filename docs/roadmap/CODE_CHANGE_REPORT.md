# Code-change report — public readiness packaging

**Date:** 2026-07-23  
**Mode:** Packaging complete; **no automatic push or release tag**.  
**Scope:** Crane + marketplaces + plugin remotes (authorized packages 1–2 and marketplace remotes).

## Summary

Authorized public-readiness packaging is implemented locally (and plugin remotes pushed where required for SoT). Reviewers should use [PUSH_PLAN.md](PUSH_PLAN.md) before publishing remotes for Crane/marketplaces.

## What changed (this goal + prior unpushed hygiene)

### Crane (`daosys/lib/indexedex/lib/crane`)

| Area | Change |
|------|--------|
| Tasks / root war room | Deleted `tasks/`; moved planning/funding to `docs/archive/internal-plans/`; bulk archive → [crane-archive](https://github.com/cyotee/crane-archive) |
| Agent skills | Removed bazaar set (~97 from `.claude/skills`, mirrors on `.grok`/`.agents`); **kept** product + borderline (crane-*, protocols, foundry, tevm/wagmi/voltaire, ethskills, etc.) |
| Docs honesty | `docs/protocols/status.md`, `docs/reference/CENTRALLY_COMPUTED_NATSPEC_VALUES.md`, SUMMARY/README links, AGENTS/CLAUDE solc **0.8.35**, no active `tasks/` workflow |
| OSS front door | SECURITY, CONTRIBUTING, NOTICE, `.env.example`, CHANGELOG, rewritten README/getting-started (prior) |
| Config | `@ozu/` remapping → `contracts/external/openzeppelin-upgradeable/`; package version `0.1.0-public-preview` (still `private: true`); npm canonical note; gitignore `out_*/` `cache_*/` |
| Verification | `scripts/verify_public_surface.sh` structural gate |

### `defi-agent-skills`

| Area | Change |
|------|--------|
| Plugin remotes (pushed) | Deepened runbooks on foundry-agent, defi-primitives, balancer-v3-ops, bankr-ops, indexedex-ops |
| Marketplace | Submodule pins bumped to those commits; MIT LICENSE + README (prior) |

### `cyotee-claude-plugins`

| Area | Change |
|------|--------|
| Local-source plugins | Published GitHub remotes: `permit2-skill`, `tevm-skill`, `wagmi-skill`, `chainlink-skill`, `reliquary-skill` |
| Catalog | `marketplace.json` sources → GitHub; Codex dual-ship regenerated |

## Part B backlog status (code standards)

| ID | Status |
|----|--------|
| C-01 solc doc alignment | **Done** (AGENTS/CLAUDE → 0.8.35) |
| C-02 dead tasks/PRD paths | **Done** (AGENTS paths fixed) |
| C-03 package version | **Partial** — version preview string; still `private: true` (intentional for library) |
| C-04 dual lockfile | **Deferred** — npm documented as canonical; `yarn.lock` not deleted |
| C-06 remappings | **Done** — both `remappings.txt` and `foundry.toml` use `@ozu/=contracts/external/openzeppelin-upgradeable/`; verified with `forge remappings` (single line, no typo path) |
| C-09 CI honesty | **Done** (status.md + CONTRIBUTING/README) |
| C-10 out_*/cache_* ignore | **Done** |
| C-21 NatSpec public path | **Done** |
| C-41 maturity matrix | **Done** (`docs/protocols/status.md`) |
| C-20 core NatSpec audit | **Remaining** (phased; factories already strong) |
| C-22 TODO triage | **Remaining** |
| C-30–34 testing | **Remaining** (not announce packaging) |
| C-40 external dedup | **Remaining** |
| M-01 ops runbooks | **Done** (Shipping plugins deepened) |
| M-02 GitHub remotes | **Done** |
| M-03 bazaar purge | **Done** |

## Explicitly not done (non-goals)

- `git push` of Crane / marketplace monorepos  
- Release tags  
- Full monorepo NatSpec rewrite  
- Completing protocol ports  
- GitHub Security Advisories UI enablement (human ops)  
- Deleting `yarn.lock`  

## How to re-verify packaging

```bash
# Crane
bash scripts/verify_public_surface.sh

# Optional
FOUNDRY_PROFILE=ci forge build -j 1
```

Evidence from the implementer session also under the goal scratch dir (`skills-after.txt`, `docs-honesty.txt`, `ops-skills.txt`, `marketplace-sources.txt`, `review-artifacts.txt`, `forge-ci.txt`).
