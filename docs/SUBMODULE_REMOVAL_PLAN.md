# Submodule Removal Plan

**Created:** 2026-01-31
**Updated:** 2026-01-31
**Status:** Phase 1 & 2 Complete

## Summary

Reduced submodule count from **26 to 7** (73% reduction), significantly improving worktree creation performance.

---

## Current State: 7 Submodules

| Submodule | Import Count | Porting Difficulty | Status |
|-----------|--------------|-------------------|--------|
| `forge-std` | 100+ (tests) | ❌ Not practical | KEEP |
| `openzeppelin-contracts` | 261 across 116 files | ❌ Not practical | KEEP |
| `solady` | 10 files (1 library) | ✅ Easy | REMOVABLE |
| ~~`solmate`~~ | ~~0 direct usage~~ | ~~✅ Easy~~ | ✅ REMOVED |
| `reclamm` | 301 across 78 files | ⚠️ Complex | KEEP (for now) |
| `permit2` | 48 across 23 files | ⚠️ Moderate | IN PROGRESS |
| `v4-core` | 0 direct usage | ✅ Not used yet | REMOVABLE |
| `v4-periphery` | 0 direct usage | ✅ Not used yet | REMOVABLE |

---

## Detailed Analysis Per Submodule

### 1. forge-std (KEEP - Essential)

**Usage:** Test framework - 100+ files
**Porting Difficulty:** ❌ Not practical

The Foundry test framework is a fundamental dependency. Not worth porting.

**Recommendation:** Keep indefinitely. This is the standard for Foundry projects.

---

### 2. openzeppelin-contracts (KEEP - Essential)

**Usage:** 261 occurrences across 116 files
**Contracts Used:**
- Token standards: IERC20, IERC165, IERC721, IERC4626
- Security: ReentrancyGuard, Ownable, AccessControl
- Utilities: SafeERC20, ECDSA, ERC165, cryptography
- Governance: Governor contracts

**Porting Difficulty:** ❌ Not practical

OpenZeppelin contracts are the industry standard. They receive regular security audits and updates. Porting would be a maintenance burden and security risk.

**Recommendation:** Keep indefinitely.

---

### 3. solady (REMOVABLE - Easy)

**Usage:** 10 files, single import
**Only Import Used:**
```solidity
import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";
```

**Files Using It:**
- `contracts/utils/BetterEfficientHashLib.sol`
- `contracts/protocols/utils/permit2/EIP712.sol`
- `contracts/protocols/utils/permit2/PermitHash.sol`
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol`
- `contracts/protocols/dexes/camelot/v2/stubs/UniswapV2ERC20.sol`
- `contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProvider*.sol`

**Porting Difficulty:** ✅ Easy (single library ~200 lines)

**Work Required:**
1. Copy `EfficientHashLib.sol` to `contracts/utils/solady/EfficientHashLib.sol`
2. Update remapping: `@solady/utils/EfficientHashLib.sol=contracts/utils/solady/EfficientHashLib.sol`
3. Remove `lib/solady` submodule

**Estimated Effort:** 30 minutes

**Recommendation:** Port to remove submodule. Low risk since it's a pure utility library.

---

### 4. solmate (✅ REMOVED)

**Status:** Removed on 2026-01-31

**What was done:**
1. Removed from `.gitmodules`
2. Removed `lib/solmate` directory
3. Removed `@solmate/` remapping
4. Created `contracts/test/mocks/MockERC20.sol` to replace solmate's mock
5. Updated `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/UniswapV3PeripheryRepo.t.sol`

**Note:** Other submodules (permit2, v4-*) have their own solmate copy in their lib/. Removing the top-level solmate didn't affect them.

---

### 5. reclamm (KEEP - Complex Dependencies)

**Usage:** 301 occurrences across 78 files
**Provides:**
- `@balancer-labs/v3-interfaces/` - Balancer V3 interfaces
- `@balancer-labs/v3-vault/` - Vault contracts
- `@balancer-labs/v3-pool-utils/` - Pool utilities
- `@balancer-labs/v3-pool-weighted/` - Weighted pool implementation
- `@balancer-labs/v3-solidity-utils/` - Utility libraries

**Porting Difficulty:** ⚠️ Complex

The reclamm submodule provides access to the full Balancer V3 monorepo. Porting would require:
- Extracting specific interfaces and libraries
- Maintaining compatibility with Balancer V3 protocol updates
- Significant refactoring of import paths

**Work Required (if porting):**
1. Identify all specific contracts/interfaces used
2. Port each to `contracts/protocols/dexes/balancer/v3/`
3. Update ~78 files with new import paths
4. Update remappings
5. Test extensively

**Estimated Effort:** 2-3 days

**Recommendation:** Keep for now. Port later if Balancer V3 integration stabilizes.

---

### 6. permit2 (IN PROGRESS - Partially Ported)

**Usage:** 48 occurrences across 23 files
**Current State:** Interfaces already ported with remappings

**Already Ported:**
```
permit2/src/interfaces/IPermit2.sol → contracts/interfaces/protocols/utils/permit2/IPermit2.sol
permit2/src/interfaces/IAllowanceTransfer.sol → contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol
permit2/src/interfaces/ISignatureTransfer.sol → contracts/interfaces/protocols/utils/permit2/ISignatureTransfer.sol
permit2/src/interfaces/IEIP712.sol → contracts/interfaces/IEIP712.sol
permit2/src/interfaces/IDAIPermit.sol → contracts/interfaces/protocols/utils/permit2/IDAIPermit.sol
permit2/test/utils/DeployPermit2.sol → contracts/protocols/utils/permit2/test/utils/DeployPermit2.sol
```

**Still Needed:**
- `contracts/protocols/utils/permit2/AllowanceTransfer.sol` - partially ported
- `contracts/protocols/utils/permit2/SignatureTransfer.sol` - partially ported
- `contracts/protocols/utils/permit2/Permit2Lib.sol` - needs testing

**Blocking Tasks:**
- CRANE-168: Add SafeCast160 Unit Tests
- CRANE-169: Add Permit2Lib Integration Tests
- CRANE-170: Document DeployPermit2 Bytecode Source

**Work Required:**
1. Complete SafeCast160 tests
2. Complete Permit2Lib integration tests
3. Verify all edge cases
4. Remove fallback remapping `permit2/=lib/permit2/`
5. Remove `lib/permit2` submodule

**Estimated Effort:** 4-6 hours (mostly testing)

**Recommendation:** Complete blocking tasks, then remove.

---

### 7. v4-core (REMOVABLE - Not Used)

**Usage:** 0 direct imports in `contracts/`
**Status:** Submodule present but not integrated yet

The remapping exists:
```
v4-core/=lib/v4-periphery/lib/v4-core/src/
```

But no Crane contracts import from it directly.

**Porting Difficulty:** ✅ N/A (not used)

**Work Required:**
1. Confirm no direct usage (verified: 0 imports)
2. If V4 integration is planned: port when needed
3. If not planned: remove submodule and remapping

**Recommendation:**
- **If V4 work is planned (CRANE-152):** Keep until porting is done
- **If V4 work is NOT planned:** Remove immediately

---

### 8. v4-periphery (REMOVABLE - Not Used)

**Usage:** 0 direct imports in `contracts/`
**Status:** Submodule present but not integrated yet

Same situation as v4-core.

**Recommendation:** Same as v4-core above.

---

## Recommended Removal Order

### Immediate (No Risk)

1. ~~**solmate** - Not used at all~~ ✅ DONE
2. **v4-core** + **v4-periphery** - Not used (unless V4 work is planned)

### Short-term (Easy Port)

3. **solady** - Port EfficientHashLib (~30 min)

### Medium-term (Testing Required)

4. **permit2** - Complete tests, then remove (~4-6 hours)

### Long-term (Complex)

5. **reclamm** - Only if Balancer V3 integration stabilizes (~2-3 days)

### Keep Indefinitely

- **forge-std** - Test framework essential
- **openzeppelin-contracts** - Industry standard, security audited

---

## Final Target State

| Phase | Submodules | Count |
|-------|------------|-------|
| ~~Original~~ | ~~forge-std, openzeppelin, solady, solmate, reclamm, permit2, v4-core, v4-periphery~~ | ~~8~~ |
| **Current** | forge-std, openzeppelin, solady, reclamm, permit2, v4-core, v4-periphery | **7** |
| After Immediate | forge-std, openzeppelin, solady, reclamm, permit2 | 5 |
| After Short-term | forge-std, openzeppelin, reclamm, permit2 | 4 |
| After Medium-term | forge-std, openzeppelin, reclamm | 3 |
| After Long-term | forge-std, openzeppelin | 2 |

**Best achievable:** 2 submodules (forge-std + openzeppelin)
**Practical target:** 3-4 submodules (keep reclamm until Balancer V3 matures)

---

## Completed Work (This Session)

### Removed 18 Submodules

**Phase 1 - Unused:**
- scaffold-eth-2, solplot, solidity-lib, evc-playground
- aave-v3-horizon, aave-v4, comet
- euler-vault-kit, euler-price-oracle, evk-periphery
- ethereum-vault-connector, balancer-v3-monorepo

**Phase 2 - Already Ported:**
- aerodrome-contracts, slipstream → `contracts/protocols/dexes/aerodrome/`
- v3-core, v3-periphery → `contracts/protocols/dexes/uniswap/v3/`
- resupply → `contracts/protocols/cdps/resupply/`
- gsn → `contracts/protocols/utils/gsn/` (Forwarder only)

### Ported GSN Forwarder

Created:
- `contracts/protocols/utils/gsn/forwarder/Forwarder.sol`
- `contracts/protocols/utils/gsn/forwarder/IForwarder.sol`

Updated:
- `contracts/protocols/dexes/aerodrome/v1/stubs/ProtocolForwarder.sol`
- `contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol`

### Removed solmate (Session 2)

- Removed `lib/solmate` submodule
- Removed `@solmate/` remapping
- Created `contracts/test/mocks/MockERC20.sol` (local replacement)
- Updated `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/UniswapV3PeripheryRepo.t.sol`

---

## Related Tasks

| Task ID | Description | Status |
|---------|-------------|--------|
| CRANE-148 | Verify Aerodrome Contract Port Completeness | ✅ Complete |
| CRANE-150 | Verify Permit2 Contract Port Completeness | ✅ Complete |
| CRANE-151 | Port and Verify Uniswap V3 Core + Periphery | ✅ Complete |
| CRANE-152 | Port and Verify Uniswap V4 Core + Periphery | 🔄 Ready |
| CRANE-168 | Add SafeCast160 Unit Tests | 🔄 In Progress |
| CRANE-169 | Add Permit2Lib Integration Tests | 🔄 Ready |
| CRANE-170 | Document DeployPermit2 Bytecode Source | 🔄 In Progress |
| CRANE-171 | Remove lib/permit2 Submodule | ⏸️ Blocked |
| CRANE-181 | Remove lib/aerodrome-contracts Submodule | ✅ Complete |
| CRANE-182 | Final Submodule Cleanup | 🔄 In Progress |
| CRANE-186 | Remove v3-core and v3-periphery Submodules | ✅ Complete |
| NEW | Port EfficientHashLib from solady | 📋 Ready |
| NEW | Remove solmate submodule | ✅ Complete |
| NEW | Remove v4-core + v4-periphery submodules | 📋 Ready (if not needed) |
