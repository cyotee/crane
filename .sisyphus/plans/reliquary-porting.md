# Reliquary Porting Plan (v2 — Updated)

## Context

The Reliquary project (an ERC721-based yield/reward manager with maturity curves, pluggable rewarders, and deposit helpers) was installed as a git submodule at `lib/Reliquary`. The goal is to port its code into Crane so the submodule can be removed and the ported code used directly in Crane tests.

---

## Phase 0: Dependency Inventory

### Crane already has (reuse these — no changes needed)

| Reliquary import | Crane location | Action |
|---|---|---|
| `openzeppelin-contracts/contracts/token/ERC721/ERC721.sol` | `contracts/external/openzeppelin/token/ERC721/ERC721.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/utils/math/Math.sol` | `contracts/external/openzeppelin/utils/math/Math.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/utils/math/SafeCast.sol` | `contracts/external/openzeppelin/utils/math/SafeCast.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol` | `contracts/utils/ReentrancyGuard.sol` (Solady-backed) | Replace with Crane's `contracts/utils/ReentrancyGuard.sol` |
| `openzeppelin-contracts/contracts/utils/Multicall.sol` | `contracts/external/openzeppelin/utils/Multicall.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/utils/Strings.sol` | `contracts/external/openzeppelin/utils/Strings.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol` | `contracts/external/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol` | `contracts/utils/SafeERC20.sol` | Replace with Crane's `SafeERC20` (Solady-backed) |
| `openzeppelin-contracts/contracts/access/Ownable.sol` | `contracts/access/Ownable.sol` | Replace with Crane's `Ownable` (Solady-backed) |
| `openzeppelin-contracts/contracts/interfaces/IERC4626.sol` | `contracts/interfaces/IERC4626.sol` | Reuse — update import path |
| `openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol` | `contracts/external/openzeppelin/utils/structs/EnumerableSet.sol` | Reuse — update import path |
| `base64/base64.sol` | `contracts/utils/Base64.sol` | Reuse — update import path |
| `v2-core/...` (Uniswap V2) | `contracts/protocols/dexes/uniswap/v2/stubs/` | Use Crane's stubs, update import paths |

### Need to port (missing in Crane)

| Missing dependency | Source file | Destination |
|---|---|---|
| `AccessControlEnumerable` | `lib/Reliquary/lib/openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol` | `contracts/external/openzeppelin/access/extensions/AccessControlEnumerable.sol` |

**Note**: `AccessControl` (base class) is also needed by `AccessControlEnumerable`. If `AccessControl` is not in Crane, port it too.

---

## Phase 1: Directory Structure

Create the following under `contracts/protocols/staking/reliquary/v1/`:

```
contracts/protocols/staking/reliquary/v1/
├── interfaces/
│   ├── IReliquary.sol
│   ├── IRewarder.sol
│   ├── IRollingRewarder.sol
│   ├── IParentRollingRewarder.sol
│   ├── INFTDescriptor.sol
│   └── ICurves.sol
├── curves/
│   ├── LinearCurve.sol
│   ├── LinearPlateauCurve.sol
│   └── PolynomialPlateauCurve.sol
├── rewarders/
│   ├── RollingRewarder.sol
│   └── ParentRollingRewarder.sol
├── nft_descriptors/
│   └── NFTDescriptor.sol
├── helpers/
│   ├── DepositHelperERC4626.sol
│   ├── DepositHelperReaperVault.sol
│   └── DepositHelperReaperBPT.sol
└── services/
    ├── ReliquaryLogic.sol    (renamed from ReliquaryLogic → ReliquaryService)
    └── ReliquaryEvents.sol
```

Main contract goes at:
```
contracts/protocols/staking/reliquary/v1/Reliquary.sol
```

Test structure:
```
test/foundry/spec/protocols/dexes/reliquary/v1/
├── Reliquary.t.sol
├── DepositHelperERC4626.t.sol
├── DepositHelperReaperVault.t.sol
├── DepositHelperReaperBPT.t.sol
├── MultipleRollingRewarder.t.sol
└── mocks/
    └── ERC20Mock.sol
```

Test base goes at:
```
contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol
```

---

## Phase 2: OpenZeppelin Dependency Porting

### 2.1 Port AccessControlEnumerable

**Source**: `lib/Reliquary/lib/openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol`

**Destination**: `contracts/external/openzeppelin/access/extensions/AccessControlEnumerable.sol`

Also port these OZ files if they don't exist in Crane (check before porting):
- `lib/Reliquary/lib/openzeppelin-contracts/contracts/access/AccessControl.sol` → `contracts/external/openzeppelin/access/AccessControl.sol`

Import update in ported files: change `openzeppelin-contracts/` prefix to `@crane/contracts/external/openzeppelin/` (or the appropriate Crane path).

---

## Phase 3: Source Code Porting

### 3.1 Port interfaces

Files (in order):
1. `lib/Reliquary/contracts/interfaces/IReliquary.sol`
2. `lib/Reliquary/contracts/interfaces/IRewarder.sol`
3. `lib/Reliquary/contracts/interfaces/IRollingRewarder.sol`
4. `lib/Reliquary/contracts/interfaces/IParentRollingRewarder.sol`
5. `lib/Reliquary/contracts/interfaces/INFTDescriptor.sol`
6. `lib/Reliquary/contracts/interfaces/ICurves.sol`

### 3.2 Port curves

Files:
1. `lib/Reliquary/contracts/curves/LinearCurve.sol`
2. `lib/Reliquary/contracts/curves/LinearPlateauCurve.sol`
3. `lib/Reliquary/contracts/curves/PolynomialPlateauCurve.sol`

### 3.3 Port rewarders

Files:
1. `lib/Reliquary/contracts/rewarders/RollingRewarder.sol`
2. `lib/Reliquary/contracts/rewarders/ParentRollingRewarder.sol`

**Import updates**:
- `SafeERC20` → `contracts/utils/SafeERC20.sol`
- `Ownable` → `contracts/access/Ownable.sol`
- `AccessControlEnumerable` → `contracts/external/openzeppelin/access/extensions/AccessControlEnumerable.sol`

### 3.4 Port NFT descriptor

File: `lib/Reliquary/contracts/nft_descriptors/NFTDescriptor.sol`

**Import updates**:
- `Strings` → `@crane/contracts/external/openzeppelin/utils/Strings.sol`
- `IERC20Metadata` → `@crane/contracts/external/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol`
- `base64/base64.sol` → `@crane/contracts/utils/Base64.sol`

### 3.5 Port helpers

Files:
1. `lib/Reliquary/contracts/helpers/DepositHelperERC4626.sol`
2. `lib/Reliquary/contracts/helpers/DepositHelperReaperVault.sol`
3. `lib/Reliquary/contracts/helpers/DepositHelperReaperBPT.sol`

**Import updates**:
- `SafeERC20` → `contracts/utils/SafeERC20.sol`
- `Ownable` → `contracts/access/Ownable.sol`
- `IERC4626` → `contracts/interfaces/IERC4626.sol`

### 3.6 Port services

Files:
1. `lib/Reliquary/contracts/libraries/ReliquaryLogic.sol` → `services/ReliquaryService.sol` (rename)
2. `lib/Reliquary/contracts/libraries/ReliquaryEvents.sol` → `services/ReliquaryEvents.sol`

**Import updates**:
- `SafeERC20` → `contracts/utils/SafeERC20.sol`
- `Math` → `@crane/contracts/external/openzeppelin/utils/math/Math.sol`
- `SafeCast` → `@crane/contracts/external/openzeppelin/utils/math/SafeCast.sol`

### 3.7 Port main Reliquary contract

File: `lib/Reliquary/contracts/Reliquary.sol`

**Import updates**:
- `SafeERC20` → `contracts/utils/SafeERC20.sol`
- `ERC721` → `@crane/contracts/external/openzeppelin/token/ERC721/ERC721.sol`
- `AccessControlEnumerable` → `contracts/external/openzeppelin/access/extensions/AccessControlEnumerable.sol`
- `ReentrancyGuard` → `contracts/utils/ReentrancyGuard.sol`
- `Math` → `@crane/contracts/external/openzeppelin/utils/math/Math.sol`
- `Multicall` → `@crane/contracts/external/openzeppelin/utils/Multicall.sol`
- `SafeCast` → `@crane/contracts/external/openzeppelin/utils/math/SafeCast.sol`

---

## Phase 4: Test Porting (Crane TestBase Pattern)

### 4.1 Create TestBase_Reliquary

Location: `contracts/protocols/staking/reliquary/v1/test/bases/TestBase_Reliquary.sol`

Based on existing patterns (e.g., `TestBase_CamelotV2.sol`, `TestBase_UniswapV2.sol`), the TestBase should:
- Inherit from Crane's `CraneTest` (which provides factory infrastructure)
- Deploy the ported Reliquary contract
- Set up mock ERC20 tokens for rewardToken and pool tokens
- Provide virtual helper functions for creating pools, depositing, etc.
- Follow Crane's TestBase conventions (virtual `_deploy()`, `setUp()` etc.)

### 4.2 Port test files

Port each test file, updating:
- Import paths from `lib/Reliquary/` to new Crane locations
- Replace `import "forge-std/Test.sol"` with Crane test base
- Replace Reliquary-specific deployment with `TestBase_Reliquary` inheritance
- Keep test logic intact (deposit/withdraw/split/merge/harvest tests)
- Port `mocks/ERC20Mock.sol` → `test/foundry/spec/protocols/dexes/reliquary/v1/mocks/ERC20Mock.sol`

Files:
1. `lib/Reliquary/test/foundry/Reliquary.t.sol`
2. `lib/Reliquary/test/foundry/DepositHelperERC4626.t.sol`
3. `lib/Reliquary/test/foundry/DepositHelperReaperVault.t.sol`
4. `lib/Reliquary/test/foundry/DepositHelperReaperBPT.t.sol`
5. `lib/Reliquary/test/foundry/MultipleRollingRewarder.t.sol`
6. `lib/Reliquary/test/foundry/mocks/ERC20Mock.sol`

### 4.3 Reference existing Crane mocks

Use Crane's existing `contracts/test/mocks/MockERC20.sol` for simple ERC20 mocks. Only create a new mock if Reliquary's mock has special behavior (minting, decimals override, etc.).

---

## Phase 5: Import Path Update Rules

Summary of import transformations:

| Old import (OZ path) | New import (Crane path) |
|---|---|
| `openzeppelin-contracts/contracts/token/ERC721/ERC721.sol` | `@crane/contracts/external/openzeppelin/token/ERC721/ERC721.sol` |
| `openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol` | `@crane/contracts/utils/SafeERC20.sol` |
| `openzeppelin-contracts/contracts/access/Ownable.sol` | `@crane/contracts/access/Ownable.sol` |
| `openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol` | `@crane/contracts/external/openzeppelin/access/extensions/AccessControlEnumerable.sol` |
| `openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol` | `@crane/contracts/utils/ReentrancyGuard.sol` |
| `openzeppelin-contracts/contracts/utils/math/Math.sol` | `@crane/contracts/external/openzeppelin/utils/math/Math.sol` |
| `openzeppelin-contracts/contracts/utils/math/SafeCast.sol` | `@crane/contracts/external/openzeppelin/utils/math/SafeCast.sol` |
| `openzeppelin-contracts/contracts/utils/Multicall.sol` | `@crane/contracts/external/openzeppelin/utils/Multicall.sol` |
| `openzeppelin-contracts/contracts/utils/Strings.sol` | `@crane/contracts/external/openzeppelin/utils/Strings.sol` |
| `openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol` | `@crane/contracts/external/openzeppelin/utils/structs/EnumerableSet.sol` |
| `openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol` | `@crane/contracts/external/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol` |
| `openzeppelin-contracts/contracts/interfaces/IERC4626.sol` | `@crane/contracts/interfaces/IERC4626.sol` |
| `base64/base64.sol` | `@crane/contracts/utils/Base64.sol` |
| `v2-core/...` | Use Crane stubs at `contracts/protocols/dexes/uniswap/v2/stubs/` |

---

## Phase 6: Submodule Removal

After all code is ported and tests pass:

```bash
# From Crane root
git submodule deinit lib/Reliquary
git rm lib/Reliquary
git add .gitmodules
git commit -m "chore: remove Reliquary submodule after porting to protocols/dexes/reliquary/v1"
```

---

## Phase 7: Verification Checklist

- [ ] `forge build` succeeds — no errors in ported contracts
- [ ] `forge test` passes — all Reliquary tests pass under Crane's test runner
- [ ] `forge fmt` formats all ported files
- [ ] No remaining imports referencing `lib/Reliquary/` in Crane codebase
- [ ] `lib/Reliquary/` directory removed from Crane root
- [ ] LSP diagnostics clean on all ported files

---

## Files to Port (Summary)

| Source | Destination |
|---|---|
| `lib/Reliquary/contracts/Reliquary.sol` | `contracts/protocols/staking/reliquary/v1/Reliquary.sol` |
| `lib/Reliquary/contracts/libraries/ReliquaryLogic.sol` | `contracts/protocols/staking/reliquary/v1/services/ReliquaryService.sol` |
| `lib/Reliquary/contracts/libraries/ReliquaryEvents.sol` | `contracts/protocols/staking/reliquary/v1/services/ReliquaryEvents.sol` |
| `lib/Reliquary/contracts/interfaces/*.sol` | `contracts/protocols/staking/reliquary/v1/interfaces/` |
| `lib/Reliquary/contracts/curves/*.sol` | `contracts/protocols/staking/reliquary/v1/curves/` |
| `lib/Reliquary/contracts/rewarders/*.sol` | `contracts/protocols/staking/reliquary/v1/rewarders/` |
| `lib/Reliquary/contracts/nft_descriptors/*.sol` | `contracts/protocols/staking/reliquary/v1/nft_descriptors/` |
| `lib/Reliquary/contracts/helpers/*.sol` | `contracts/protocols/staking/reliquary/v1/helpers/` |
| `lib/Reliquary/test/foundry/*.sol` | `test/foundry/spec/protocols/dexes/reliquary/v1/` |
| `lib/Reliquary/test/foundry/mocks/ERC20Mock.sol` | `test/foundry/spec/protocols/dexes/reliquary/v1/mocks/ERC20Mock.sol` |
| `lib/Reliquary/lib/openzeppelin-contracts/contracts/access/extensions/AccessControlEnumerable.sol` | `contracts/external/openzeppelin/access/extensions/AccessControlEnumerable.sol` |
| `lib/Reliquary/lib/openzeppelin-contracts/contracts/access/AccessControl.sol` | `contracts/external/openzeppelin/access/AccessControl.sol` (if needed) |

---

## Implementation Order

1. **Port AccessControlEnumerable + AccessControl** (needed by main contract)
2. **Port interfaces** (no external deps, just ABI definitions)
3. **Port curves** (no external deps)
4. **Port services** (ReliquaryService, ReliquaryEvents — only internal deps)
5. **Port Reliquary.sol** (depends on services, interfaces, OZ imports)
6. **Port rewarders** (depend on interfaces, OZ)
7. **Port helpers** (depend on Reliquary, OZ)
8. **Port NFT descriptor** (depends on interfaces, base64)
9. **Create TestBase_Reliquary** (follow existing TestBase pattern)
10. **Port tests** (depend on TestBase, ported contracts, mocks)
11. **Run `forge build` + `forge test`**
12. **Remove submodule**
