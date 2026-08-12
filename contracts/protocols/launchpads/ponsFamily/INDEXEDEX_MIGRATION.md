# IndexedEx / consumer migration — ponsFamily v1 / v2 layout

**Date:** 2026-08-11  
**Audience:** Agents or humans updating IndexedEx (or any Crane consumer) after the ponsFamily reorg + production port.  
**Scope:** Import path changes, what was ported, production APIs for creator fee recipients, remaining gaps.

---

## Why this changed

1. **Reorganize** domain code by protocol generation: `v1/` and `v2/` under `contracts/protocols/launchpads/ponsFamily/`.
2. **Complete the production port:**
   - V1 **locker** was missing from GitHub; recovered from **Sourcify** and vendored.
   - V2 domain contracts are now public on GitHub and vendored under `v2/`.

---

## Old → new import map (Solidity)

Base prefix: `@crane/contracts/protocols/launchpads/ponsFamily`

| Old path | New path |
|----------|----------|
| `.../ponsFamily/pons/PonsLaunchFactory.sol` | `.../ponsFamily/v1/PonsLaunchFactory.sol` |
| `.../ponsFamily/pons/PonsLauncherToken.sol` | `.../ponsFamily/v1/PonsLauncherToken.sol` |
| `.../ponsFamily/pons/interfaces/ILaunchpad.sol` | `.../ponsFamily/v1/interfaces/ILaunchpad.sol` |
| `.../ponsFamily/pons/libraries/PonsLiquidityMath.sol` | `.../ponsFamily/v1/libraries/PonsLiquidityMath.sol` |
| `.../ponsFamily/pons/libraries/PonsTickMath.sol` | `.../ponsFamily/v1/libraries/PonsTickMath.sol` |
| `.../ponsFamily/stubs/PonsLaunchLockerStub.sol` | `.../ponsFamily/v1/stubs/PonsLaunchLockerStub.sol` |
| `.../ponsFamily/test/bases/TestBase_PonsFamily.sol` | `.../ponsFamily/v1/test/bases/TestBase_PonsFamily.sol` |
| `.../ponsFamily/test/bases/TestBase_PonsFamily_Fork.sol` | `.../ponsFamily/v1/test/bases/TestBase_PonsFamily_Fork.sol` |
| *(none — new)* | `.../ponsFamily/v1/PonsLaunchLocker.sol` |
| *(none — new)* | `.../ponsFamily/v2/**` (see inventory below) |

### Bulk replace (recommended)

```bash
# From IndexedEx (or monorepo) root — dry-run with rg first
rg -n 'launchpads/ponsFamily/pons/|launchpads/ponsFamily/stubs/|launchpads/ponsFamily/test/bases/'

# Example sed (macOS)
find . -name '*.sol' -print0 | xargs -0 sed -i '' \
  -e 's|protocols/launchpads/ponsFamily/pons/|protocols/launchpads/ponsFamily/v1/|g' \
  -e 's|protocols/launchpads/ponsFamily/stubs/|protocols/launchpads/ponsFamily/v1/stubs/|g' \
  -e 's|protocols/launchpads/ponsFamily/test/bases/|protocols/launchpads/ponsFamily/v1/test/bases/|g'
```

Relative imports that pointed at `../pons/...` need the same `v1/` segment.

---

## Prefer production locker over the stub

| Component | Use when |
|-----------|----------|
| **`v1/PonsLaunchLocker.sol`** | Hermetic deploy, fee claim/redirect tests, anything that must match production fee split |
| **`v1/stubs/PonsLaunchLockerStub.sol`** | Only if you need a deliberately incomplete double; **not** production-faithful |

### Hermetic wiring (production pattern)

```solidity
// 1) Deploy locker (owner, protocol fee recipient, default protocol share %)
PonsLaunchLocker locker = new PonsLaunchLocker(owner, protocolFeeRecipient, 30);

// 2) Deploy factory with locker address
PonsLaunchFactory factory = new PonsLaunchFactory(owner, address(locker), launchFee);

// 3) Bind factory on locker (one-time)
locker.initialize(address(factory));
```

Crane’s `TestBase_PonsFamily` already does this.

### Creator fee recipient (V1 production)

| When | API |
|------|-----|
| At launch | `TokenParams.feeWallet` → factory calls `locker.setFeeRedirect(token, feeWallet)` |
| After launch | **Deployer** (or factory) calls `locker.setFeeRedirect(token, newFeeWallet)` |
| Claim | `locker.collectFees(token)` — pays redirect if set, else `launched.deployer`; protocol share snapshotted per token |
| Read redirect | `locker.feeRedirects(token)` (**plural** — not stub’s `feeRedirect`) |

Callers authorized for `collectFees`: owner, deployer, current fee recipient, or owner-enabled `feeCollectors`.

### Creator fee recipient (V2 production)

| When | API |
|------|-----|
| At launch | `params.creatorFeeRecipient` (zero → original deployer) |
| After launch (self-serve) | `factory.transferCreatorFeeRecipient(token, newRecipient)` — only current recipient |
| Protocol override | `setCreatorFeeRecipient` + timelock + `executeCreatorFeeRecipientChange` |
| Claim | Pull from **fee escrow** (`PonsV2FeeEscrow.claim` / `claimToken`) |

---

## V2 inventory (new under Crane)

```
v2/
├── PonsV2LaunchFactory.sol
├── PonsV2BondingCurve.sol
├── PonsV2LaunchDeployer.sol
├── PonsV2LauncherToken.sol
├── PonsV2GraduationGuard.sol
├── PonsV2GraduationExecutor.sol
├── PonsV2LaunchLocker.sol          # permanent V4 NFT custody; no collectFees
├── PonsV2BuybackVault.sol
├── PonsV2FeeEscrow.sol             # reconstructed claim ledger (upstream source unpublished)
├── hooks/PonsV2MemeHook.sol
├── interfaces/ILaunchpadV2.sol     # includes IPonsV2FeeEscrow, fee policy, records
├── interfaces/ILaunchpadV2Graduation.sol
├── libraries/{PonsV2BondingCurveMath,PonsV2GraduationMath}.sol
└── test/bases/TestBase_PonsFamilyV2.sol  # hermetic Uni V4 + full V2 stack
```

### Shared deps (already in Crane — do not re-vendor)

| Upstream import | Crane target |
|-----------------|--------------|
| `@openzeppelin/contracts/...` | `@crane/contracts/external/openzeppelin-contracts-v5/...` |
| `@uniswap/v4-core/src/...` | `@crane/contracts/protocols/dexes/uniswap/v4/...` (FullMath → `.../uniswap/libraries/FullMath.sol`) |
| `@uniswap/v4-periphery/...` | `@crane/contracts/protocols/dexes/uniswap/v4/...` |
| `@uniswap/v4-hooks-public/.../BaseHook.sol` | `@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/base/BaseHook.sol` |
| `permit2/src/interfaces/IAllowanceTransfer.sol` | `@crane/contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol` |

### Network constants

`ROBINHOOD_MAIN` now exposes:

- `PONS_LAUNCH_FACTORY_ACTIVE` / `PONS_LAUNCH_LOCKER_ACTIVE` (V1)
- `PONS_V2_LAUNCH_FACTORY`, `PONS_V2_FEE_ESCROW`, `PONS_V2_MEME_HOOK`, `PONS_V2_LAUNCH_LOCKER`, `PONS_V2_BUYBACK_VAULT`

---

## Compile / Foundry notes

| Tree | Status |
|------|--------|
| `v1/` | Compiles on **default** profile; hermetic suite green (no RPC) |
| `v2/` | Compiles on **default** under **`via_ir = false`** after Crane stack-depth refactors. Do **not** enable viaIR. |
| Fee escrow | `PonsV2FeeEscrow.sol` reconstructed for hermetic tests; live bytecode may differ — bind `PONS_V2_FEE_ESCROW` on forks |

Profiles: **default** skips `test/foundry/fork/**` (no RPC). **`FOUNDRY_PROFILE=fork`** includes fork tests. `pons_port` is removed.

V2 pin preferred source: **Sourcify** exact_match for factory `0x7eD598…` (GitHub `main` can lag). Hermetic CREATE2 may differ from mainnet because curve/token constructors now take a single init struct (same field order; packaging differs in contract creation code).

---

## Explicit gaps for IndexedEx

1. **Fee escrow bytecode parity** — hermetic uses reconstructed `PonsV2FeeEscrow`; for production fork parity, etch or bind live `PONS_V2_FEE_ESCROW` when comparing storage/events to mainnet.
2. **V2 graduation e2e** — TestBase deploys full stack and covers launch + curve buy + fee sweep + creator redirect; full sell-out → V4 pool seed is optional follow-on coverage.
3. **Skills / docs** under `.claude/skills/pons-*` may still say “v2 not open source” or old `pons/` paths — update when convenient.
4. **Crane wrappers** (`PonsLaunchService`, AwareRepo) were never shipped; if IndexedEx added local helpers against `pons/`, repoint to `v1/`.

---

## Verification commands (Crane)

```bash
# Default profile: hermetic only (no RPC)
forge test \
  --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/hermetic/**' -vv

# Fork profile: Robinhood bind tests (needs RPC)
FOUNDRY_PROFILE=fork forge test \
  --match-path 'test/foundry/fork/protocols/launchpads/ponsFamily/**' -vv
```

After IndexedEx import rewrites:

```bash
# In IndexedEx repo — match your project’s forge/hardhat entrypoints
forge build
# or: forge test --match-path '...pons...' 
```

---

## Checklist for the IndexedEx agent

- [ ] Grep and replace all `ponsFamily/pons/`, `ponsFamily/stubs/`, `ponsFamily/test/bases/` imports → `v1/...`
- [ ] Prefer `PonsLaunchLocker` over stub for fee/claim behavior
- [ ] Replace `feeRedirect` reads with `feeRedirects` if any
- [ ] If using factory deploy in tests: add `locker.initialize(factory)` after both deploy
- [ ] For V2 product work: import from `ponsFamily/v2/...` (including `PonsV2FeeEscrow`); hermetic via `TestBase_PonsFamilyV2`; fork binds from `ROBINHOOD_MAIN`
- [ ] Run consumer compile/tests; fix any remaining relative paths
- [ ] Update IndexedEx-local docs that cite old `pons/` layout

---

## Source pins (for audits)

| Artifact | Origin |
|----------|--------|
| V1 factory/token/math | github.com/ponsdotdev/ponsfamily `contractsV1/src` (+ prior Crane stack-depth adaptations) |
| V1 locker | Sourcify chain 4663 `0x736D76699C26D0d966744cAe304C000d471f7F35` exact_match (2026-07-13) |
| V2 domain | Sourcify chain 4663 factory `0x7eD598BcEf8bd9Edd8C97A195C6d13f40801EC7e` exact_match (2026-08-04); cross-check GitHub `contractsV2/src/v2` |

See also `VENDOR.md` in this directory.
