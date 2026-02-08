# Task CRANE-239: Fix OpenGSN Forwarder Fork Test Type Hash Registration

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** -
**Worktree:** `fix/opengsn-forwarder-typehash`
**Origin:** Failing fork tests

---

## Description

Five tests in `OpenGSNForwarder_Fork.t.sol` fail because the "upstream" forwarder's request type hash is never registered. The `TestBase_OpenGSNFork.sol` imports the same Forwarder contract for both "ported" and "upstream" instances, but the test helper `_computeUpstreamRequestTypeHash()` returns a hash for `"...validUntil"` while the constructor auto-registers `"...validUntilTime"`. Since both forwarders are the same contract, the `validUntil` variant was never registered, causing `_verifySig()` to revert with `"FWD: unregistered typehash"`.

The fix should register the upstream type hash on the upstream forwarder during setUp(), and ensure the signing helpers and request builders produce consistent type hash / struct hash pairs.

## Dependencies

None.

## User Stories

### US-CRANE-239.1: Register Upstream Request Type Hash in setUp

As a developer, I want the fork test setUp to register the upstream request type on the upstream forwarder instance, so that verify/execute calls with the upstream type hash succeed.

**Acceptance Criteria:**
- [ ] `setUp()` calls `upstreamForwarder.registerRequestType(...)` with the correct type name and suffix to register the `"ForwardRequest(...validUntil)"` type hash
- [ ] `_computeUpstreamRequestTypeHash()` returns a hash that matches what `registerRequestType` actually registers (accounting for the `GENERIC_PARAMS` concatenation format)
- [ ] `_signUpstreamRequest()` uses the correct registered type hash for signing
- [ ] All 5 failing tests pass
- [ ] No other fork tests are broken

### US-CRANE-239.2: Fix Type Hash Consistency Between Registration and Usage

As a developer, I want the type hash used in verify/execute calls to exactly match what was registered, so that the forwarder's `typeHashes` mapping lookup succeeds.

**Acceptance Criteria:**
- [ ] The upstream request type hash computed in tests matches what `registerRequestTypeInternal` stores in `typeHashes`
- [ ] The struct hash encoding in `_signUpstreamRequest()` matches `_getEncoded()` for the upstream type
- [ ] `test_requestTypeHash_registered()` passes - both ported and upstream type hashes are registered
- [ ] `test_verify_validSignature()` passes - valid signatures verify on both forwarders
- [ ] `test_verify_invalidSignature_reverts()` passes - bad signatures revert with `"FWD: signature mismatch"` (not `"FWD: unregistered typehash"`)
- [ ] `test_getNonce_incrementsAfterExecute()` passes - execute succeeds and increments nonce on both
- [ ] `test_appendedSender_parity()` passes - both forwarders append sender correctly

## Technical Details

**Root Cause:**

Both `PortedForwarder` and `UpstreamForwarder` are the same contract (`@crane/contracts/protocols/utils/gsn/forwarder/Forwarder.sol`). The constructor auto-registers:

```
"ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntilTime)"
```

But the test's `_computeUpstreamRequestTypeHash()` computes the hash of:

```
"ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil)"
```

Note `validUntil` vs `validUntilTime` - different strings, different hashes. The `validUntil` hash was never registered.

**Fix Pattern:**

The `registerRequestType` function concatenates: `typeName + "(" + GENERIC_PARAMS + "," + typeSuffix`. To register a custom type that ends with `validUntil` instead of `validUntilTime`, the approach is:

**Option A (Recommended):** Since both "ported" and "upstream" are the same contract with the same `GENERIC_PARAMS` (which uses `validUntilTime`), acknowledge this and use the same type hash for both. Remove `_computeUpstreamRequestTypeHash()` or make it return the same hash as `_computeRequestTypeHash()`. This reflects reality: both forwarders use `validUntilTime`.

**Option B:** Register a custom request type on the upstream forwarder via `registerRequestType("ForwardRequest", "uint256 validUntil)")`. But note: `registerRequestType` builds the type string as `typeName + "(" + GENERIC_PARAMS + "," + typeSuffix`, so the result would be `"ForwardRequest(address from,...,uint256 validUntilTime,uint256 validUntil)"` - this adds `validUntil` as an EXTRA field after `validUntilTime`, which is wrong.

**Option A is correct** because the contract is the same. The "upstream" distinction in the test was originally intended to compare against a real upstream OpenGSN forwarder (which uses `validUntil`), but since both instances are the same ported contract, they both use `validUntilTime`.

**Signing helper fix:**
- `_signUpstreamRequest()` already encodes `req.validUntilTime` (line 204 in TestBase), which is correct for the ported contract's struct
- The `_buildUpstreamRequest()` sets `validUntilTime: block.number + 1000` (line 255) - note this uses `block.number` not `block.timestamp`, which is inconsistent with the ported version. Both should probably use `block.timestamp`.

**Key insight:** The `IUpstreamForwarder.ForwardRequest` struct is actually `IForwarder.ForwardRequest` (same import), so the `validUntilTime` field is already the correct field name.

**Failing Tests:**

| Test | Error | Root Cause |
|------|-------|------------|
| `test_requestTypeHash_registered()` | `Upstream type hash not registered` | `_computeUpstreamRequestTypeHash()` returns unregistered hash |
| `test_verify_validSignature()` | `FWD: unregistered typehash` | Passes unregistered upstream type hash to `verify()` |
| `test_verify_invalidSignature_reverts()` | `FWD: unregistered typehash != FWD: signature mismatch` | Reverts at type hash check before reaching signature check |
| `test_getNonce_incrementsAfterExecute()` | `FWD: unregistered typehash` | Passes unregistered upstream type hash to `execute()` |
| `test_appendedSender_parity()` | `FWD: unregistered typehash` | Passes unregistered upstream type hash to `execute()` |

## Files to Create/Modify

**Modified Files:**
- `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol` - Fix type hash registration and upstream helpers

**Specifically:**
1. Remove or update `_computeUpstreamRequestTypeHash()` to return the same hash as `_computeRequestTypeHash()` (since both contracts are identical)
2. Update `setUp()` if needed to register any additional type hashes
3. Optionally add a comment explaining that "upstream" and "ported" use the same contract
4. Fix `_buildUpstreamRequest()` to use `block.timestamp` instead of `block.number` for `validUntilTime` (consistency)

## Inventory Check

Before starting, verify:
- [ ] `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol` exists
- [ ] `test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol` exists
- [ ] `contracts/protocols/utils/gsn/forwarder/Forwarder.sol` exists
- [ ] Fork test infrastructure works (INFURA_KEY available)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-contract OpenGSNForwarder_Fork --match-path "test/foundry/fork/ethereum_main/gsn/*"` passes all tests
- [ ] `forge build` passes
- [ ] No other fork tests broken

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
