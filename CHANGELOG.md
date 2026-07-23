# Changelog

## Unreleased

### Public packaging

- Remove in-repo CRANE task system and agent session dumps from the default branch.
- Move historical planning/funding notes under `docs/archive/internal-plans/`.
- Externalize bulk gap reports and research scrapes to [cyotee/crane-archive](https://github.com/cyotee/crane-archive).
- Add SECURITY.md, CONTRIBUTING.md, NOTICE.md, `.env.example`.
- Rewrite README and getting-started for a framework-first public surface.
- Publish protocol maturity status and public NatSpec values reference.
- Curate agent skills: keep Crane/protocol/Foundry/borderline tooling; remove bazaar noise.

### Config

- Align agent docs with Solidity **0.8.35** (Foundry pin).
- Fix OpenZeppelin upgradeable remapping typo (`@ozu/`).
- Prefer **npm** lockfile; document yarn as non-canonical if both remain temporarily.
