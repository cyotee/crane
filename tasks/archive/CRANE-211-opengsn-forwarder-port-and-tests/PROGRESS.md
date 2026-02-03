# Progress Log: CRANE-211

## Current Checkpoint

**Last checkpoint:** Task complete
**Next step:** Code review
**Build status:** ✅ Passing
**Test status:** ✅ 16/16 tests passing

---

## Final Summary

### Files Created

| File | Purpose |
|------|---------|
| `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol` | Fork test base with EIP-712 signing helpers |
| `test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol` | 16 parity tests |
| `test/foundry/fork/ethereum_main/gsn/RecipientStub.sol` | Test recipient for appended sender verification |

### Dependencies

- `lib/gsn` installed from https://github.com/opengsn/gsn at commit `8e0c9ed23d9798b7384e8255054631c3cb414fdf` (v2.2.5)
- Remapping: `@opengsn/contracts/=lib/gsn/packages/contracts/` (pre-existing in foundry.toml)

### Test Coverage

**16 tests covering:**
- Domain separator registration and computation
- Request type hash registration
- getNonce initial and post-execute behavior
- verify() valid/invalid signatures, wrong nonce, unregistered domain/typehash
- execute() success, target revert, ETH value transfer
- Appended sender extraction (parity between ported and upstream)
- ERC165 interface support (ported enhancement)

### Port Validation

The ported Forwarder was validated against upstream:
- ✅ License: GPL-3.0-only (matches upstream)
- ✅ Attribution present
- ✅ Compiles with Solidity 0.8.30
- ✅ Core signing/verification behavior matches

**Intentional differences (enhancements):**
1. `validUntilTime` (timestamp) vs `validUntil` (block number)
2. ERC165 support added
3. Dry-run address check for simulation

---

## Session Log

### 2026-02-03 (Continued)

#### Completed: Fork Parity Test Implementation

**Files Created:**
- `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol` - Base test contract with:
  - Fork setup at block 21,000,000
  - Deploys both ported and upstream Forwarders
  - EIP-712 signing helpers for both implementations
  - Request builder functions
  - INFURA_KEY skip logic

- `test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol` - 16 parity tests covering:
  - Domain separator registration and computation
  - Request type hash registration
  - getNonce behavior (initial and after execute)
  - verify() with valid/invalid signatures, wrong nonce, unregistered domain/typehash
  - execute() success, target revert, and ETH value transfer
  - Appended sender semantics (Forwarder appends 20 bytes to calldata)
  - ERC165 interface support (ported enhancement)

- `test/foundry/fork/ethereum_main/gsn/RecipientStub.sol` - Test recipient that:
  - Extracts appended sender from calldata
  - Provides functions for success, revert, and value receipt testing

**Upstream Pin:**
- Installed `lib/gsn` from https://github.com/opengsn/gsn
- Checked out commit `8e0c9ed23d9798b7384e8255054631c3cb414fdf` (v2.2.5)
- Remapping already in foundry.toml: `@opengsn/contracts/=lib/gsn/packages/contracts/`

**Test Results:**
```
Ran 16 tests for test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol:OpenGSNForwarder_Fork
[PASS] test_appendedSender_parity() (gas: 667971)
[PASS] test_appendedSender_semantics() (gas: 175602)
[PASS] test_domainSeparator_computation() (gas: 10013)
[PASS] test_domainSeparator_registration() (gas: 20060)
[PASS] test_execute_success() (gas: 174425)
[PASS] test_execute_targetReverts() (gas: 59783)
[PASS] test_execute_withValue() (gas: 107806)
[PASS] test_getNonce_incrementsAfterExecute() (gas: 309142)
[PASS] test_getNonce_initial() (gas: 19673)
[PASS] test_requestTypeHash_registered() (gas: 18214)
[PASS] test_supportsInterface() (gas: 7026)
[PASS] test_verify_invalidSignature_reverts() (gas: 60298)
[PASS] test_verify_unregisteredDomain_reverts() (gas: 26733)
[PASS] test_verify_unregisteredTypeHash_reverts() (gas: 28807)
[PASS] test_verify_validSignature() (gas: 58933)
[PASS] test_verify_wrongNonce_reverts() (gas: 37792)
Suite result: ok. 16 passed; 0 failed; 0 skipped
```

#### Validated: Port Completeness (US-CRANE-211.1)

- ✅ Ported files exist at `contracts/protocols/utils/gsn/forwarder/`
- ✅ License: GPL-3.0-only (matches upstream)
- ✅ Attribution: `@dev Ported from OpenGSN (https://github.com/opengsn/gsn)`
- ✅ Compiles with Solidity 0.8.30

**Intentional Differences from Upstream:**
1. Field name: `validUntilTime` (timestamp) vs `validUntil` (block number)
2. Expiry check: `block.timestamp` vs `block.number`
3. ERC165 support: Ported version implements `supportsInterface()`
4. Dry-run check: Ported adds `tx.origin == DRY_RUN_ADDRESS` for simulation

### 2026-02-02

- Task created
- Recorded historical submodule pin for `lib/gsn` (OpenGSN)
