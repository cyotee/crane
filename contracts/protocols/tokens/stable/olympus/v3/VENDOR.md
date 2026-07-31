# Olympus V3 (Bophades) vendor / port pin

| Item | Value |
|------|-------|
| Upstream | [OlympusDAO/olympus-v3](https://github.com/OlympusDAO/olympus-v3) |
| Pin | `0af8d56dbe78850d120f077b355dcecee56cb83f` |
| Path | `contracts/protocols/tokens/stable/olympus/v3` |
| Tests | `test/foundry/spec/protocols/tokens/stable/olympus/v3` |
| Domain `.sol` (in-tree) | 158 (+ Crane wrappers under services/aware/test) |
| Test `.sol` (in-tree) | ≥150 hermetic + wrapper suite |
| Copy date | 2026-07-29 |
| License | AGPL-3.0-only (SPDX on sources) |
| Bootstrap | Copy-forward from Crane `olympus/v2` research tree (same pin) then path remap to `v3` |
| Import policy | Shared OZ v4/v5, Solmate, Uniswap V3, clones-with-immutable-args remapped to `@crane/contracts/external/...`; no private OZ/Solmate trees under olympus |
| Dual tree | Research pin also at `olympus/v2` + `FOUNDRY_PROFILE=olympus_port` (same upstream commit at copy time) |

## Build / test

```bash
FOUNDRY_PROFILE=olympus_v3_port forge build
FOUNDRY_PROFILE=olympus_v3_port forge test --match-path 'test/foundry/spec/protocols/tokens/stable/olympus/v3/**'
FOUNDRY_PROFILE=olympus_v3_port forge test
```

Profile: solc 0.8.35, `optimizer_runs=1`, `via_ir=false`, `ffi=true`, `ast=true` (Quabi godmode fixtures read forge AST under `out_olympus_v3_port`).

## Scope included (Default Framework core)

- `Kernel.sol`, `Submodules.sol`
- Modules: MINTR, TRSRY, ROLES, INSTR, VOTES, RANGE, CHREG, BLREG, RGSTY, DLGTE (+ supporting interfaces)
- Bases, libraries, policy utils/admin (RolesAdmin, TreasuryCustodian, Emergency, Minter, Reserve*, ContractRegistryAdmin, Parthenon, …)
- Protocol-unique externals: OlympusERC20 (OHM), OlympusAuthority, Cooler stack, clones helpers
- Hermetic Foundry suite for Kernel, core modules, bases, policy utils, rate limiter invariants
- Crane wrappers: `services/`, `aware/`, `test/bases/` (Service + AwareRepo + TestBase)

## Explicitly excluded from in-tree Crane suite

| Exclusion | Reason |
|-----------|--------|
| `src/scripts/**`, `src/proposals/**`, proposal-sim tests | Ops / forge-proposal-simulator |
| `src/test/sim/**` | ffi/shell sim |
| CCIP/LZ bridge policies, periphery bridge, CrossChainBridge | Network bridge stacks |
| `*Fork*` tests | Mainnet RPC (follow-up) |
| Deposit facility / DEPOS / PRICE.v2 feed suites | Large periphery; re-add when needed |
| Bond/Operator/Clearinghouse/Heart integration suite | Heavy bond market stack |
| Cooler V2 **policies** (MonoCooler, …) | Follow-up; Cooler **external** included |

Any test that **is** under `test/foundry/spec/protocols/tokens/stable/olympus/v3/**` must pass.

## Adaptations

- Pragma exact pins relaxed to `>=` for Crane solc 0.8.35
- Imports rewritten to `@crane/...` paths under `olympus/v3`
- Shared deps: OZ v4 primary + v5 where upstream used 5.3; Solmate; Uniswap V3 core/periphery (OracleLibrary); clones-with-immutable-args
- Quabi helpers: `lib/quabi/{path,jq}.sh` resolve artifacts under `out_olympus_v3_port`
- No `via_ir`
