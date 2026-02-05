# Task CRANE-220: Port Solady Code to Remove Submodule Dependency

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-04
**Dependencies:** None
**Worktree:** `feature/solady-port`

---

## Description

Port all required Solady code to local Crane contracts, enabling removal of the `lib/solady` submodule. The Solady usage is limited to `EfficientHashLib` across 10 files. The porting strategy is to inline the Solady assembly optimizations into `BetterEfficientHashLib.sol`, then update all direct Solady imports to use the local library. Success is verified when no `@solady` imports remain and the build compiles without the remapping.

## Dependencies

None - this is a standalone refactoring task.

## User Stories

### US-CRANE-220.1: Inline EfficientHashLib Assembly into BetterEfficientHashLib

As a developer, I want the Solady `EfficientHashLib` assembly inlined into `BetterEfficientHashLib.sol` so that wrapper functions contain optimized hashing logic directly.

**Acceptance Criteria:**
- [ ] Copy `EfficientHashLib.hash()` assembly implementations for 1-14 arguments into `BetterEfficientHashLib`
- [ ] Copy buffer hashing operations (`hash(bytes32[])`, `set`, `malloc`, `free`)
- [ ] Copy equality check operations (`eq`)
- [ ] Copy byte slice hashing operations (`hash(bytes, start, end)`, etc.)
- [ ] Copy SHA-256 helper operations (`sha2`, `sha2Calldata`)
- [ ] Remove `import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";`
- [ ] Remove `using EfficientHashLib for ...` statements
- [ ] Add MIT license header noting code ported from Solady

### US-CRANE-220.2: Update Direct Solady Imports

As a developer, I want all files directly importing from Solady updated to use local code so the submodule can be removed.

**Acceptance Criteria:**
- [ ] Update `contracts/protocols/utils/permit2/EIP712.sol` - replace Solady import with local
- [ ] Update `contracts/protocols/utils/permit2/PermitHash.sol` - replace Solady import with local
- [ ] Update `contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol` - replace Solady import
- [ ] Update `contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol` - replace Solady import
- [ ] Update `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol` - replace Solady import
- [ ] Update `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol` - replace Solady import
- [ ] Update `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol` - replace Solady import
- [ ] Remove commented-out imports in `ERC2612Target.sol` and `ERC20DFPkg.sol` (already disabled)

### US-CRANE-220.3: Verify Submodule Removal

As a developer, I want confirmation that the Solady submodule can be safely removed.

**Acceptance Criteria:**
- [ ] `grep -r "@solady" contracts/` returns no results
- [ ] Remove `@solady/` remapping from `foundry.toml`
- [ ] `forge build` succeeds without Solady remapping
- [ ] All existing tests pass (`forge test`)

## Technical Details

### Files Using Solady

| File | Usage | Action |
|------|-------|--------|
| `contracts/utils/BetterEfficientHashLib.sol` | Wrapper around EfficientHashLib | Inline assembly |
| `contracts/protocols/utils/permit2/EIP712.sol` | `using EfficientHashLib for bytes` | Use BetterEfficientHashLib |
| `contracts/protocols/utils/permit2/PermitHash.sol` | `using EfficientHashLib for bytes` | Use BetterEfficientHashLib |
| `contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol` | EfficientHashLib import | Use BetterEfficientHashLib |
| `contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol` | EfficientHashLib import | Use BetterEfficientHashLib |
| `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol` | EfficientHashLib import | Use BetterEfficientHashLib |
| `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol` | EfficientHashLib import | Use BetterEfficientHashLib |
| `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol` | EfficientHashLib import | Use BetterEfficientHashLib |
| `contracts/tokens/ERC2612/ERC2612Target.sol` | Commented out import | Remove comment |
| `contracts/tokens/ERC20/ERC20DFPkg.sol` | Commented out import | Remove comment |

### Assembly Inlining Strategy

The `BetterEfficientHashLib` currently wraps Solady by delegating all calls:

**Before:**
```solidity
import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

library BetterEfficientHashLib {
    function _hash(bytes32 v0, bytes32 v1) internal pure returns (bytes32 result) {
        return EfficientHashLib.hash(v0, v1);  // Delegates to Solady
    }
}
```

**After:**
```solidity
// No Solady import needed

/// @notice Ported from Solady EfficientHashLib (MIT License)
/// @author Solady (https://github.com/vectorized/solady)
library BetterEfficientHashLib {
    function _hash(bytes32 v0, bytes32 v1) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, v0)
            mstore(0x20, v1)
            result := keccak256(0x00, 0x40)
        }
    }
}
```

### Consumer Update Strategy

Files that directly import EfficientHashLib need to switch to BetterEfficientHashLib:

**Before:**
```solidity
import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

contract EIP712 {
    using EfficientHashLib for bytes;

    function _buildDomainSeparator(...) private view returns (bytes32) {
        return abi.encode(...).hash();
    }
}
```

**After:**
```solidity
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

contract EIP712 {
    using BetterEfficientHashLib for bytes;

    function _buildDomainSeparator(...) private view returns (bytes32) {
        return abi.encode(...)._hash();  // Note: underscore prefix in BetterEfficientHashLib
    }
}
```

### API Differences

Note that `BetterEfficientHashLib` uses underscore-prefixed function names (`_hash`, `_set`, `_malloc`, etc.) while Solady uses unprefixed names. Consumer code may need function name updates.

### License Headers

All ported assembly code must include:
```solidity
// SPDX-License-Identifier: MIT
// Solady EfficientHashLib (https://github.com/vectorized/solady)
// Ported to Crane Framework
```

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/BetterEfficientHashLib.sol` - Inline Solady assembly, remove import
- `contracts/protocols/utils/permit2/EIP712.sol` - Update import and function names
- `contracts/protocols/utils/permit2/PermitHash.sol` - Update import and function names
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol` - Update import
- `contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol` - Update import
- `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol` - Update import
- `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol` - Update import
- `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol` - Update import
- `contracts/tokens/ERC2612/ERC2612Target.sol` - Remove commented import
- `contracts/tokens/ERC20/ERC20DFPkg.sol` - Remove commented import
- `foundry.toml` - Remove `@solady/` remapping

**Reference File:**
- `lib/solady/src/utils/EfficientHashLib.sol` - Source of assembly to port

**Tests:**
- Existing tests should continue to pass
- Consider adding hash equivalence tests comparing ported vs original Solady behavior

## Inventory Check

Before starting, verify:
- [ ] Location of Solady submodule (`lib/solady/`)
- [ ] Full content of `EfficientHashLib.sol` for porting
- [ ] Current `@solady/` remapping in `foundry.toml`
- [ ] All 10 files with Solady imports identified

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] No `@solady/` imports remain in `contracts/` (verified by grep)
- [ ] `@solady/` remapping removed from `foundry.toml`
- [ ] `forge build` succeeds without Solady
- [ ] All existing tests pass (`forge test`)
- [ ] MIT license headers preserved on ported assembly code

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
