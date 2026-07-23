# Push plan / checklist (human gate)

**Do not push or tag until a human reviews this list and explicitly approves.**

## Already published (plugin remotes)

These were pushed as part of packaging SoT requirements:

| Remote | Purpose |
|--------|---------|
| https://github.com/cyotee/crane-archive | Bulk docs archive |
| https://github.com/cyotee/foundry-agent-skills | Ops skill deepen |
| https://github.com/cyotee/defi-primitives-ops | Ops skill deepen |
| https://github.com/cyotee/balancer-v3-ops | Ops skill deepen |
| https://github.com/cyotee/bankr-ops | Ops skill deepen |
| https://github.com/cyotee/indexedex-ops | Ops skill deepen |
| https://github.com/cyotee/permit2-skill | Marketplace plugin |
| https://github.com/cyotee/tevm-skill | Marketplace plugin |
| https://github.com/cyotee/wagmi-skill | Marketplace plugin |
| https://github.com/cyotee/chainlink-skill | Marketplace plugin |
| https://github.com/cyotee/reliquary-skill | Marketplace plugin |

## Pending push (local commits only)

### 1. Crane — `https://github.com/cyotee/crane`

```bash
cd daosys/lib/indexedex/lib/crane
git log origin/main..HEAD --oneline
git status -sb
# AFTER review:
git push origin main
```

Expected subjects (among others):

- hygiene: tasks purge, archive externalize, README/SECURITY  
- packaging: skill curation, docs honesty, config alignment  

### 2. defi-agent-skills — `https://github.com/cyotee/defi-agent-skills`

```bash
cd defi-agent-skills   # or workspace path
git log origin/main..HEAD --oneline
# AFTER review:
git push origin main
```

Includes LICENSE/README + submodule pin bumps.

### 3. cyotee-claude-plugins — `https://github.com/cyotee/cyotee-claude-plugins`

```bash
cd cyotee-claude-plugins
git log origin/main..HEAD --oneline
# AFTER review:
git push origin main
```

Includes LICENSE/README + marketplace.json GitHub sources + Codex regenerate.

## After push (optional, separate approval)

- [ ] Enable GitHub Security Advisories private reporting on `cyotee/crane`
- [ ] Confirm Pages docs build for Crane
- [ ] Run `FOUNDRY_PROFILE=ci forge test` on CI / locally
- [ ] Tag only if desired: `v0.1.0-public-preview` (**not** done by packaging agent)
- [ ] Announcement draft linking Crane + both marketplaces + docs

## Policy

- **No automatic push** from the packaging agent after this plan.  
- **No release tag** until human OK.  
- Plugin remotes above were intentionally published so marketplace installs resolve.
