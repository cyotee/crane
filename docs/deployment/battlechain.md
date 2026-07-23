# BattleChain Security Gate

Before promoting Crane core factories, DFPkgs, or significant protocol ports to Base or mainnet, they **must** survive BattleChain.

## Why BattleChain

BattleChain (chain ID 627 testnet / 626 mainnet) provides adversarial "attack mode" with whitehats and automated tools. It is the required quality bar for anything that will be reused by many agents and projects.

See AGENTS.md and:

- Pilot: `scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol`
- **IndexedEx launch promo (Wave A):** `scripts/foundry/Script_Promo_BC_Launch.s.sol` — Crane core + ERC20Permit + Uni V2/V4 + Permit2 + Safe Harbor; **use BC-provided WETH + Uni V3**
- Consumer plan: IndexedEx `docs/BATTLECHAIN_LAUNCH_PROMO.md`

## Practice: use BattleChain-provided contracts

**Do not redeploy or replace** anything BattleChain already ships (testnet mock/dependency contracts or genesis infrastructure). Bind to their addresses and only create3-deploy **Crane-owned** surfaces that are missing.

| Provided on BC testnet (examples) | Wave A action |
|-----------------------------------|---------------|
| WETH `0x4CAc…1f42` | **Use** |
| Uniswap V3 Factory / SwapRouter / NPM | **Use** |
| USDC, DAI, Chainlink mocks, Safe, … | **Use** when needed |
| Uni V2, Uni V4 PoolManager, Permit2, Crane factories | **Deploy** via Crane create3 |

Source: [BattleChain mock & dependency contracts](https://docs.battlechain.com/battlechain/reference/mock-contracts).

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

## Deployed addresses

Wave A is **live** on BattleChain testnet (block 17158).

- [Deployed Addresses](./deployed-addresses.md)
- Machine JSON: [`addresses/battlechain-sepolia.json`](./addresses/battlechain-sepolia.json)
- Solidity: `contracts/constants/networks/BC_TESTNET.sol` (`CREATE3_FACTORY`, `WETH`, Uni V2/V3/V4, etc.)

The promo script refreshes the JSON/table on re-broadcast.

## See also

- [CREATE3 & New Chain Setup](create3.md)
- [Deployed Addresses](./deployed-addresses.md)
- [Testing Patterns](../development/testing.md)
- [Getting Started](../getting-started.md)
