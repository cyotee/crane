# Contributing to Crane

Thanks for helping improve Crane. This repository is a Diamond-first (ERC-2535) Solidity framework with Foundry tests and AI-agent skills.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (forge, cast, anvil)
- Git with submodule support
- Optional: Node/npm if you touch Hardhat or TS tooling

## Setup

```bash
git clone --recurse-submodules https://github.com/cyotee/crane.git
cd crane
# if you cloned without submodules:
git submodule update --init --recursive
forge build
```

## Build and test

Full monorepo builds can be heavy. CI and day-to-day core work use the **ci** profile:

```bash
FOUNDRY_PROFILE=ci forge build
FOUNDRY_PROFILE=ci forge test
```

Default profile compiles a wider surface (including protocol ports). Prefer the ci profile unless you are changing those areas.

Targeted tests:

```bash
forge test --match-path test/foundry/spec/factories/** -vvv
forge test --match-contract YourTest -vvv
```

Format:

```bash
forge fmt
```

## Documentation

- Product docs live under `docs/` and are listed in `docs/SUMMARY.md`.
- GitHub Pages is built with mdBook via `scripts/build_docs_pages.sh`.
- Do not add internal planning dumps, coverage logs, or task trackers at the repo root.

Preview docs locally (requires [mdBook](https://rust-lang.github.io/mdBook/)):

```bash
bash scripts/build_docs_pages.sh
mdbook serve --open
```

## Code standards

Authoritative conventions are in **[AGENTS.md](AGENTS.md)** and the docs under `docs/development/`:

- Facet-Target-Repo storage pattern
- NatSpec + include-tag / selector requirements for public interfaces
- **No viaIR** — use structs and helpers to avoid stack-too-deep
- Production-first testing (`TestBase_*`, `Behavior_*`) over mocks when possible

## AI agent skills

Skills ship under `.claude/skills/`. Prefer updating an existing skill when patterns change.

External marketplaces (optional install for agents):

- Developer / architecture: [cyotee/cyotee-claude-plugins](https://github.com/cyotee/cyotee-claude-plugins) (`crane@cyotee`)
- On-chain ops (separate product surface): [cyotee/defi-agent-skills](https://github.com/cyotee/defi-agent-skills)

## Pull requests

1. Keep PRs focused (one concern: docs, factories, a single port, etc.).
2. Include or update tests for behavior changes.
3. Update docs or skills when you change public patterns.
4. Do not commit secrets, `.env` files, or machine-local agent settings.
5. Do not reintroduce a root `tasks/` work-item tree.

## Security

Do not file public issues for vulnerabilities. See [SECURITY.md](SECURITY.md).

## License

Crane-native code is licensed under the **AGPL-3.0**. Vendored dependencies retain their original licenses — see [NOTICE.md](NOTICE.md) and `licenses/`.
