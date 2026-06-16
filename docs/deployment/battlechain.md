# BattleChain Security Gate

Before promoting Crane core factories, DFPkgs, or significant protocol ports to Base or mainnet, they **must** survive BattleChain.

## Why BattleChain

BattleChain (chain ID 627 testnet / 626 mainnet) provides adversarial "attack mode" with whitehats and automated tools. It is the required quality bar for anything that will be reused by many agents and projects.

See AGENTS.md and the pilot script: `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol`.

## Process

1. Implement + test locally (Foundry invariants, behavior tests).
2. Use `InitBcService` (BattleChain-aware bootstrap) in deployment scripts.
3. Deploy to BattleChain testnet.
4. Create Safe Harbor agreement (scope the Create3Factory with appropriate child contract scope).
5. Enable attack mode and monitor.
6. Survive testing → promote to PRODUCTION on BattleChain.
7. Re-deploy **identical** bytecode (same salts) to Base / target mainnets.

Only after this gate do we consider a component "production-grade" for the shared framework.

## For Agents

When an agent is asked to port or build core infrastructure:
- Follow the gate explicitly.
- Document pilot scripts and results.
- Update this page and AGENTS.md in consumer repos.

Failure to respect the gate risks fund loss for users of reusable packages.

## References

- `contracts/InitBcService.sol`
- BattleChain docs (LLM-friendly): https://docs.battlechain.com/llms-full.txt
- Pilot examples in `scripts/`
