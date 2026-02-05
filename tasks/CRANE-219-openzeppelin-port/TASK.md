# Task CRANE-219: Port OpenZeppelin Code to Remove Submodule Dependency

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-04
**Dependencies:** None
**Worktree:** `feature/openzeppelin-port`

---

## Description

Port all required OpenZeppelin contracts to local Crane contracts, enabling the eventual removal of the `lib/openzeppelin-contracts` submodule. This task involves three patterns: (1) replacing pure re-export wrapper files with the full ported interface/implementation, (2) inlining wrapped OZ logic into existing Crane wrapper libraries, and (3) updating imports in externally-ported contracts (Balancer V3, Uniswap V3/V4, Aerodrome, etc.).

## Dependencies

None - this is a standalone refactoring task.

## User Stories

### US-CRANE-219.1: Port OpenZeppelin Interfaces

As a developer, I want all OpenZeppelin interfaces ported locally so that imports resolve without the submodule.

**Acceptance Criteria:**
- [ ] Port `IERC20`, `IERC20Metadata`, `IERC20Permit` to `contracts/interfaces/`
- [ ] Port `IERC165` to `contracts/interfaces/`
- [ ] Port `IERC721`, `IERC721Metadata`, `IERC721Enumerable`, `IERC721Receiver` to `contracts/interfaces/`
- [ ] Port `IERC1155Receiver` to `contracts/interfaces/`
- [ ] Port `IERC1271` (signature verification) to `contracts/interfaces/`
- [ ] Port `IERC1363` (payment token) to `contracts/interfaces/`
- [ ] Port `IERC4626` (vault standard) to `contracts/interfaces/`
- [ ] Port `IERC5267` (EIP-712 metadata) to `contracts/interfaces/`
- [ ] Port `IERC6372` (clock functions) to `contracts/interfaces/`
- [ ] Port `draft-IERC6093` error interfaces (`IERC20Errors`, `IERC721Errors`, `IERC1155Errors`) to `contracts/interfaces/`
- [ ] All interface files include original MIT license headers

### US-CRANE-219.2: Port OpenZeppelin Utility Libraries

As a developer, I want all OZ utility libraries ported locally so that wrapper libraries can inline their logic.

**Acceptance Criteria:**
- [ ] Port `Math.sol` and inline into `BetterMath.sol`
- [ ] Port `SafeCast.sol` to `contracts/utils/math/`
- [ ] Port `SafeERC20.sol` and inline into `BetterSafeERC20.sol`
- [ ] Port `Address.sol` and inline/merge with `BetterAddress.sol`
- [ ] Port `Strings.sol` and inline/merge with `BetterStrings.sol`
- [ ] Port `Arrays.sol` and inline/merge with `BetterArrays.sol`
- [ ] Port `Bytes.sol` and inline/merge with `BetterBytes.sol`
- [ ] Port `Base64.sol` to `contracts/utils/`
- [ ] Port `Create2.sol` to `contracts/utils/`
- [ ] Port `Context.sol` to `contracts/utils/`
- [ ] Port `StorageSlot.sol` to `contracts/utils/`
- [ ] Port `TransientSlot.sol` to `contracts/utils/`
- [ ] Port `ShortStrings.sol` to `contracts/utils/`
- [ ] Port `Panic.sol` to `contracts/utils/`
- [ ] All utility files include original MIT license headers

### US-CRANE-219.3: Port OpenZeppelin Cryptography Modules

As a developer, I want cryptography utilities ported so that EIP-712 and signature verification work without OZ imports.

**Acceptance Criteria:**
- [ ] Port `ECDSA.sol` to `contracts/utils/cryptography/`
- [ ] Port `EIP712.sol` to `contracts/utils/cryptography/`
- [ ] Port `Nonces.sol` to `contracts/utils/cryptography/`
- [ ] Port `SignatureChecker.sol` to `contracts/utils/cryptography/`
- [ ] Update `EIP712Repo.sol` to use ported code
- [ ] Update `ERC5267Facet.sol` and `ERC5267Target.sol` to use ported code
- [ ] All cryptography files include original MIT license headers

### US-CRANE-219.4: Port OpenZeppelin Token Implementations

As a developer, I want token implementations ported for test mocks and base contracts.

**Acceptance Criteria:**
- [ ] Port `ERC20.sol` to `contracts/external/openzeppelin/token/ERC20/`
- [ ] Port `ERC20Permit.sol` to `contracts/external/openzeppelin/token/ERC20/extensions/`
- [ ] Port `ERC165.sol` to `contracts/external/openzeppelin/utils/introspection/`
- [ ] Update `MockERC20.sol` to use ported ERC20
- [ ] All token implementation files include original MIT license headers

### US-CRANE-219.5: Port OpenZeppelin Data Structures

As a developer, I want data structures ported for use in governance and staking contracts.

**Acceptance Criteria:**
- [ ] Port `EnumerableSet.sol` to `contracts/utils/structs/`
- [ ] Port `DoubleEndedQueue.sol` to `contracts/utils/structs/`
- [ ] Port `Checkpoints.sol` to `contracts/utils/structs/`
- [ ] All data structure files include original MIT license headers

### US-CRANE-219.6: Port OpenZeppelin Proxy Utilities

As a developer, I want proxy utilities ported for factory and deployment patterns.

**Acceptance Criteria:**
- [ ] Port `Clones.sol` to `contracts/utils/`
- [ ] Update `DiamondPackageCallBackFactory.sol` if it uses OZ proxy code
- [ ] All proxy utility files include original MIT license headers

### US-CRANE-219.7: Port OpenZeppelin Access Control (Minimal)

As a developer, I want minimal access control utilities ported for compatibility.

**Acceptance Criteria:**
- [ ] Port `Ownable.sol` to `contracts/access/` (if used anywhere)
- [ ] Port `Context.sol` (already covered in utilities)
- [ ] Assess if any governance contracts need `AccessControl.sol`
- [ ] All access control files include original MIT license headers

### US-CRANE-219.8: Port OpenZeppelin MetaTx Support

As a developer, I want meta-transaction support ported for GSN forwarder compatibility.

**Acceptance Criteria:**
- [ ] Port `ERC2771Context.sol` to `contracts/metatx/`
- [ ] Update `Forwarder.sol` imports if needed
- [ ] All metatx files include original MIT license headers

### US-CRANE-219.9: Inline Wrapper Logic

As a developer, I want Crane wrapper libraries to have OZ logic inlined, eliminating wrapper-to-OZ imports.

**Acceptance Criteria:**
- [ ] `BetterMath.sol`: Inline all OZ `Math.sol` functions, remove `using Math for ...` pattern
- [ ] `BetterSafeERC20.sol`: Inline all OZ `SafeERC20.sol` functions, remove `using SafeERC20 for ...`
- [ ] `BetterAddress.sol`: Inline all OZ `Address.sol` functions
- [ ] `BetterStrings.sol`: Inline all OZ `Strings.sol` functions
- [ ] `BetterArrays.sol`: Inline all OZ `Arrays.sol` functions
- [ ] `BetterBytes.sol`: Inline all OZ `Bytes.sol` functions
- [ ] All wrapper files maintain their existing public API signatures
- [ ] Add NatSpec noting functions were ported from OpenZeppelin with MIT license

### US-CRANE-219.10: Update External Protocol Imports

As a developer, I want externally-ported contracts to use local OZ code so the submodule can be removed.

**Acceptance Criteria:**
- [ ] Update all `contracts/external/balancer/v3/` imports from `@openzeppelin/` to local paths
- [ ] Update all `contracts/protocols/dexes/balancer/v3/` imports
- [ ] Update all `contracts/protocols/dexes/uniswap/v3/` imports
- [ ] Update all `contracts/protocols/dexes/uniswap/v4/` imports
- [ ] Update all `contracts/protocols/dexes/aerodrome/` imports
- [ ] Update all `contracts/protocols/utils/` imports (permit2, gsn)
- [ ] Update all `contracts/tokens/` imports
- [ ] Verify no remaining `@openzeppelin/` imports exist in contracts/

### US-CRANE-219.11: Replace Pure Re-export Files

As a developer, I want re-export wrapper files replaced with full ported content.

**Acceptance Criteria:**
- [ ] `contracts/interfaces/IERC20.sol`: Replace single import with full IERC20 interface
- [ ] `contracts/interfaces/IERC165.sol`: Replace single import with full IERC165 interface
- [ ] `contracts/interfaces/IERC5267.sol`: Replace single import with full IERC5267 interface
- [ ] `contracts/interfaces/IERC20Permit.sol`: Replace single import with full interface
- [ ] `contracts/interfaces/IERC20Errors.sol`: Replace single import with full error definitions
- [ ] `contracts/interfaces/IERC20Metadata.sol`: Replace/verify content
- [ ] All replaced files maintain same import path for consumers

### US-CRANE-219.12: Version Upgrade and Verification

As a developer, I want the port to use the latest OpenZeppelin 5.x for newest features and fixes.

**Acceptance Criteria:**
- [ ] Identify current OZ version in submodule
- [ ] Download/reference latest OZ 5.x release
- [ ] Port from latest OZ 5.x code
- [ ] Document any API differences between versions
- [ ] Update any code that relies on deprecated OZ APIs

## Technical Details

### File Organization

Ported OZ code should follow this structure:
```
contracts/
├── external/
│   └── openzeppelin/           # Full OZ implementations (ERC20, ERC165, etc.)
│       ├── token/
│       │   ├── ERC20/
│       │   │   ├── ERC20.sol
│       │   │   └── extensions/
│       │   │       └── ERC20Permit.sol
│       │   └── ERC721/
│       └── utils/
│           └── introspection/
│               └── ERC165.sol
├── interfaces/                  # Interfaces (replace re-exports with full content)
│   ├── IERC20.sol              # Full interface, not just import
│   ├── IERC165.sol
│   └── ...
└── utils/
    ├── math/
    │   ├── BetterMath.sol      # OZ Math inlined
    │   └── SafeCast.sol        # Ported from OZ
    ├── cryptography/
    │   ├── ECDSA.sol
    │   ├── EIP712.sol
    │   └── ...
    ├── structs/
    │   ├── EnumerableSet.sol
    │   └── ...
    └── ...
```

### Wrapper Inlining Strategy

For libraries like `BetterMath` that wrap OZ:

**Before:**
```solidity
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

library BetterMath {
    using Math for uint256;

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.max(b);  // Delegates to OZ
    }
}
```

**After:**
```solidity
// No OZ import needed

library BetterMath {
    /// @dev Ported from OpenZeppelin Math.sol (MIT License)
    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;  // Direct implementation
    }
}
```

### License Headers

All ported files must include:
```solidity
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated vX.X.X) (path/to/original.sol)
// Ported to Crane Framework
pragma solidity ^0.8.0;
```

### Remapping Updates

After porting, update `foundry.toml`:
```toml
# Remove or comment out:
# "@openzeppelin/=lib/openzeppelin-contracts/"

# Add if using contracts/external/openzeppelin structure:
# "@openzeppelin/=contracts/external/openzeppelin/"
```

## Files to Create/Modify

**New Files (ported from OZ latest):**
- `contracts/external/openzeppelin/token/ERC20/ERC20.sol`
- `contracts/external/openzeppelin/token/ERC20/extensions/ERC20Permit.sol`
- `contracts/external/openzeppelin/utils/introspection/ERC165.sol`
- `contracts/utils/math/SafeCast.sol`
- `contracts/utils/cryptography/ECDSA.sol`
- `contracts/utils/cryptography/EIP712.sol`
- `contracts/utils/cryptography/Nonces.sol`
- `contracts/utils/cryptography/SignatureChecker.sol`
- `contracts/utils/structs/EnumerableSet.sol`
- `contracts/utils/structs/DoubleEndedQueue.sol`
- `contracts/utils/structs/Checkpoints.sol`
- `contracts/utils/Base64.sol`
- `contracts/utils/Create2.sol`
- `contracts/utils/Context.sol`
- `contracts/utils/StorageSlot.sol`
- `contracts/utils/ShortStrings.sol`
- `contracts/utils/Panic.sol`
- `contracts/utils/Clones.sol`
- `contracts/metatx/ERC2771Context.sol`
- `contracts/access/Ownable.sol` (if needed)

**Modified Files (replace re-exports with full content):**
- `contracts/interfaces/IERC20.sol`
- `contracts/interfaces/IERC165.sol`
- `contracts/interfaces/IERC5267.sol`
- `contracts/interfaces/IERC20Permit.sol`
- `contracts/interfaces/IERC20Errors.sol`
- `contracts/interfaces/IERC20Metadata.sol`
- `contracts/interfaces/IERC721.sol`
- `contracts/interfaces/IERC721Metadata.sol`
- `contracts/interfaces/IERC721Enumerated.sol`
- `contracts/interfaces/IERC4626.sol`
- `contracts/interfaces/IERC2612.sol`

**Modified Files (inline OZ logic):**
- `contracts/utils/math/BetterMath.sol`
- `contracts/tokens/ERC20/utils/BetterSafeERC20.sol`
- `contracts/utils/BetterAddress.sol`
- `contracts/utils/BetterStrings.sol`
- `contracts/utils/collections/BetterArrays.sol`
- `contracts/utils/BetterBytes.sol`

**Modified Files (update imports):**
- All 163 files currently importing from `@openzeppelin/`
- `foundry.toml` - update remappings

**Tests:**
- Ensure all existing tests pass with ported code
- Add regression tests for any OZ functions that had known edge cases

## Inventory Check

Before starting, verify:
- [ ] Current OZ version in `lib/openzeppelin-contracts`
- [ ] Latest OZ 5.x release version for porting
- [ ] Full list of unique OZ imports across all 163 files
- [ ] Existing tests that exercise OZ functionality
- [ ] Any known OZ deprecations or breaking changes in 5.x

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] No `@openzeppelin/` imports remain in `contracts/` (verified by grep)
- [ ] `forge build` succeeds
- [ ] All existing tests pass (`forge test`)
- [ ] License headers preserved on all ported code
- [ ] Submodule can be removed (deferred to separate task CRANE-182 or similar)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
