# Wave B Balancer V3 — partial deploy recovery

## What went wrong

1. **First failures:** under-gassed CREATE3 (`deployFacet`) — some facets never landed.  
2. **Later re-runs:** `TargetAlreadyExists()` on **`deployPackageWithArgs`**.

### Why packages blow up on resume

| Path | Idempotent? |
|------|-------------|
| `create3` / `deployFacet` (no ctor args) | **Yes** — factory returns existing address if code present |
| `deployPackageWithArgs` | **No** — uses `_create3WithArgs`, reverts `TargetAlreadyExists()` |

So a package that already deployed (e.g. `BalancerV3VaultDFPkg`) will fail every naive re-broadcast.

## Fix in script (done)

`Script_Promo_BC_BalancerV3.s.sol` is **resume-safe**:

- Predict CREATE3 address for each salt  
- If `code.length > 0` → **reuse** (log `reuse package` / `reuse facet`)  
- Else deploy  
- Same for plain `create3` helpers  
- `setProtocolFeeController` / agreement create wrapped for prior-run noise  

## Recovery procedure (you run this)

### 1) Re-broadcast with resume-safe script

Copy from `WAVE_B_BALANCER_V3_COMMANDS.md` (includes `-g 400` + `--skip-simulation`).

Expect logs like:

```text
reuse facet VaultLiquidityFacet 0x…
reuse package BalancerV3VaultDFPkg 0x…
deployed package BalancerV3ConstantProductPoolDFPkg 0x…   # only if still missing
```

### 2) Optional: inventory on-chain before/after

From Crane root, with RPC `battlechain-sepolia` and factory  
`0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A`:

Salts are `keccak256(abi.encode(name))` for DFPkgs/facets named in the script.

What matters operationally:

| Component | How to know it's up |
|-----------|---------------------|
| Facets | CREATE3 salt for type name has code |
| Vault / Router packages | package address has code; `packageName()` works |
| Vault / Router diamonds | non-zero from prior `deployVault` / `deployRouter` (deterministic per factory) |
| Pool packages | three DFPkg addresses have code |

After a clean run, the script writes:

- `docs/deployment/addresses/battlechain-sepolia-balancer-v3.json`
- `docs/deployment/addresses/battlechain-sepolia-balancer-v3.table.md`

### 3) Do **not** re-request attack mode on Create3Factory

Wave A already owns that root (`ContractAlreadyLinked`). Script skips attack mode when factory is linked.

## Mapping partial broadcast (historical)

From earlier `run-latest.json` (mixed; for context only):

| Step | Typical status |
|------|----------------|
| Several vault facets | some ok, some failed (gas) |
| Vault DFPkg | may exist now → TargetAlreadyExists on re-run without resume fix |
| deployVault | succeeded in one run |
| Router facets / pkg / router | mostly ok |
| Some shared pool facets | failed |
| Weighted/Stable pkgs | ok |
| ConstProd pkg | may still be missing |
| Agreement | may exist |

**Do not hand-pick old txs.** Re-run the fixed script; it fills only missing CREATE3 salts.

## Success criteria

- [ ] Script completes without `TargetAlreadyExists`  
- [ ] Manifest JSON has non-zero vault, router, three pool packages  
- [ ] `cast code <vault>` / `<router>` non-empty on BC  
- [ ] Tell agent: **Wave B Balancer V3 deployed** for docs + `BC_TESTNET`  
