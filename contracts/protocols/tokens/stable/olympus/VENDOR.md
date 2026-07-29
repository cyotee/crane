# Olympus V3 (Bophades) vendor / port pin

| Item | Value |
|------|-------|
| Upstream | [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) |
| Pin | `0af8d56dbe78850d120f077b355dcecee56cb83f` |
| Path | `contracts/protocols/tokens/stable/olympus` |
| Tests | `test/foundry/spec/protocols/tokens/stable/olympus` |
| Domain `.sol` (in-tree) | 158 |
| Test `.sol` (in-tree) | 150 |
| Copy date | 2026-07-27 |
| License | AGPL-3.0-only (SPDX on sources) |
| Import policy | Shared OZ v4/v5, Solmate, Uniswap V3, clones-with-immutable-args remapped to `@crane/contracts/external/...`; no private OZ/Solmate trees under olympus |

## Build / test

```bash
FOUNDRY_PROFILE=olympus_port forge build
FOUNDRY_PROFILE=olympus_port forge test --match-path 'test/foundry/spec/protocols/tokens/stable/olympus/**'
# profile already scopes test= to that tree; match-path optional
FOUNDRY_PROFILE=olympus_port forge test
```

Profile: solc 0.8.35, `optimizer_runs=1`, `via_ir=false`, `ffi=true`, `ast=true` (Quabi godmode fixtures read forge AST).

## Scope included (Default Framework core)

- `Kernel.sol`, `Submodules.sol`
- Modules: MINTR, TRSRY, ROLES, INSTR, VOTES, RANGE, CHREG, BLREG, RGSTY, DLGTE (+ supporting interfaces)
- Bases, libraries, policy utils/admin (RolesAdmin, TreasuryCustodian, Emergency, Minter, Reserve*, ContractRegistryAdmin, Parthenon, …)
- Protocol-unique externals: OlympusERC20 (OHM), OlympusAuthority, Cooler stack, clones helpers
- Hermetic Foundry suite for Kernel, core modules, bases, policy utils, rate limiter invariants

## Explicitly excluded from in-tree Crane suite

Documented Non-goals — not present under the Crane test path (cannot fail the suite):

| Exclusion | Reason |
|-----------|--------|
| `src/scripts/**`, `src/proposals/**`, proposal-sim tests | Ops / forge-proposal-simulator |
| `src/test/sim/**` | ffi/shell sim |
| CCIP/LZ bridge policies, periphery bridge, CrossChainBridge | Network bridge stacks |
| `*Fork*` tests | Mainnet RPC |
| Deposit facility / DEPOS / PRICE.v2 feed suites (phase-2) | Large periphery; re-add when deps hermetic |
| Bond/Operator/Clearinghouse/Heart integration suite (phase-2) | Heavy bond market stack |

Any test that **is** under `test/foundry/spec/protocols/tokens/stable/olympus/**` must pass.

## Adaptations

- Pragma exact pins relaxed to `>=` for Crane solc 0.8.35
- Imports rewritten to `@crane/...` paths
- Shared deps: OZ v4 primary + v5 where upstream used 5.3; Solmate (+ `mixins/ERC4626.sol`); Uniswap V3 core/periphery (OracleLibrary); clones-with-immutable-args; base64 for DEPOS renderer when used
- Quabi helpers: `src/test/lib/quabi/{path,jq}.sh` resolve artifacts under `out_olympus_port`
- No `via_ir`
