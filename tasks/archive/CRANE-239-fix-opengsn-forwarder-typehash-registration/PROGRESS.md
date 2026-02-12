# Progress Log: CRANE-239

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Code review
**Build status:** PASS
**Test status:** PASS - 16/16 tests pass (including all 5 previously failing)

---

## Session Log

### 2026-02-08 - Implementation Complete

**Changes made to `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol`:**

1. Added comment explaining that UpstreamForwarder and PortedForwarder are the same contract (lines 8-12)
2. Fixed `_signUpstreamRequest()` to use stored `upstreamRequestTypeHash` field instead of calling `_computeUpstreamRequestTypeHash()` which returned an unregistered hash (line 199)
3. Fixed `_buildUpstreamRequest()` to use `block.timestamp + 1 hours` instead of `block.number + 1000` for consistency with the ported request builder (line 259)

**Changes made to `test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol`:**

1. Fixed `test_requestTypeHash_registered()` to use `upstreamRequestTypeHash` field instead of `_computeUpstreamRequestTypeHash()` (line 51)
2. Replaced all remaining `_computeUpstreamRequestTypeHash()` calls with `upstreamRequestTypeHash` field (lines 90, 123, 147, 186, 332)
3. Fixed inline upstream request in `test_verify_wrongNonce_reverts()` to use `block.timestamp + 1 hours` instead of `block.number + 1000` (line 176)
4. Updated comments to clarify both forwarders share the same type hash

**Root cause:** `_computeUpstreamRequestTypeHash()` hashed `"...validUntil"` but the Forwarder constructor registers `"...validUntilTime"`. Since both PortedForwarder and UpstreamForwarder are the same contract, the fix uses the constructor-registered type hash for both.

**Test results:** `forge test --match-contract OpenGSNForwarder_Fork -vv` - 16 passed, 0 failed, 0 skipped

### 2026-02-07 - Task Created

- Task designed via /design
- TASK.md populated with requirements
- Root cause identified: _computeUpstreamRequestTypeHash() returns hash for "validUntil" but both forwarder instances use "validUntilTime"
- Both PortedForwarder and UpstreamForwarder import the same contract
- Fix: use consistent type hash since both are the same contract
- Ready for agent assignment via /backlog:launch
