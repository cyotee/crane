# Progress Log: CRANE-005

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** N/A - Task finished
**Build status:** PASS (734 artifacts)
**Test status:** PASS (137 tests - 118 ERC20/Permit + 19 EIP712)

---

## Session Log

### 2026-01-13 - Task Completed

**Completed:**
1. Reviewed all ERC20 facet contracts:
   - `ERC20Repo.sol` - Storage library
   - `ERC20Target.sol` - Core implementation
   - `ERC20Facet.sol` - Diamond facet wrapper

2. Reviewed ERC-2612 Permit implementation:
   - `ERC2612Repo.sol` - Nonce management
   - `ERC2612Target.sol` - Permit function

3. Reviewed EIP-712 domain separator:
   - `EIP712Repo.sol` - Domain separator computation
   - `Constants.sol` - Type hash definitions

4. Reviewed ERC-5267 compliance:
   - `ERC5267Target.sol` - eip712Domain() implementation
   - `ERC5267Facet.sol` - Facet wrapper

5. Reviewed test coverage:
   - `TestBase_ERC20.sol` - Invariant testing base
   - `TestBase_ERC20Permit.sol` - Permit handler testing
   - `ERC20Permit_Integration.t.sol` - Integration tests
   - `ERC20Target_EdgeCases.t.sol` - Edge case tests
   - `EIP712Repo.t.sol` - Domain separator tests

6. Created review memo at `docs/review/token-standards.md`

**Key Findings:**
- **CRITICAL:** `ERC20Target.transferFrom` does not check allowance (calls `_transfer` instead of `_transferFrom`)
- **MINOR:** Constant named `EIP721_TYPE_HASH` should be `EIP712_TYPE_HASH`
- **MINOR:** `ERC5267Facet.facetInterfaces()` allocates array of size 2 but only uses 1 slot

**Build & Test Results:**
- `forge build`: Success (734 artifacts)
- `forge test --match-path "test/foundry/spec/tokens/ERC20/*.t.sol"`: 118 tests passed
- `forge test --match-path "test/foundry/spec/utils/cryptography/*.t.sol"`: 19 tests passed

---

### 2026-01-13 - Task Launched

- Task launched via /backlog:launch
- Agent worktree created
- Ready to begin implementation

---

## Checklist

### Inventory Check
- [x] ERC20 facet reviewed
- [x] Permit implementation reviewed
- [x] EIP-712 domain separator reviewed
- [x] ERC-5267 compliance reviewed

### Deliverables
- [x] `docs/review/token-standards.md` created
- [x] `forge build` passes
- [x] `forge test` passes

---

## Summary

Created comprehensive token standards review memo documenting:
- Critical bug in `transferFrom` allowance bypass
- Minor issues with naming and array allocation
- Full EIP compliance analysis for ERC-20, ERC-2612, EIP-712, ERC-5267
- Test coverage gaps identified
- Actionable recommendations provided
