# Task CRANE-211: OpenGSN Forwarder Port + Fork Parity Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-02
**Dependencies:** None
**Worktree:** `feature/opengsn-forwarder-port-and-tests`

---

## Description

Crane previously depended on the OpenGSN `lib/gsn` submodule. The submodule was removed after porting a minimal Forwarder implementation to `contracts/protocols/utils/gsn/forwarder/`.

This task hardens that port by (1) recording the exact upstream pin that was previously used as a submodule, and (2) adding fork-parity tests that compare our ported Forwarder behavior to the upstream OpenGSN Forwarder on a mainnet fork.

Port-task dependency policy: use a temporary upstream install inside the worktree via `forge install <URL>`, pin to the commit below, run parity, then remove the installed dependency.

## Upstream Pin (historical)

Previously installed as submodule:
- Upstream repo: https://github.com/opengsn/gsn
- Pinned submodule commit: 8e0c9ed23d9798b7384e8255054631c3cb414fdf

## Dependencies

None.

## User Stories

### US-CRANE-211.1: Validate Port Completeness

As a developer, I want the OpenGSN Forwarder port verified against its upstream source so I can trust it as a meta-tx primitive in protocol tests.

**Acceptance Criteria:**
- [x] Confirm which upstream contract(s) are ported (Forwarder + interface)
- [x] Confirm the ported files carry correct license attribution (per upstream)
- [x] Confirm the ported Forwarder compiles under the repo compiler (Solidity 0.8.30)

### US-CRANE-211.2: Fork Parity Tests vs Upstream Forwarder

As a developer, I want fork-parity tests that compare the ported Forwarder to upstream OpenGSN so that behavior is provably equivalent.

**Acceptance Criteria:**
- [x] Tests are gated/skipped when `INFURA_KEY` is not set
- [x] Tests fork Ethereum mainnet using a foundry rpc alias (e.g. `ethereum_mainnet_infura`)
- [x] Deploy our ported `Forwarder` and an upstream OpenGSN `Forwarder` (from pinned upstream source) into the fork
- [x] Parity assertions cover at least:
  - domain separator / EIP-712 domain values used for request signing
  - `getNonce(from)` behavior
  - `verify(request, signature)` (valid + invalid cases)
  - `execute(request, signature)` success path and revert paths
  - appended sender semantics on recipient side (use a small test recipient)
- [x] `forge test --match-path "test/foundry/fork/ethereum_main/gsn/*.t.sol"` passes when fork enabled

## Technical Details

### Current Port Location

- `contracts/protocols/utils/gsn/forwarder/Forwarder.sol`
- `contracts/protocols/utils/gsn/forwarder/IForwarder.sol`

### Test Strategy

- Create a fork TestBase similar to existing fork suites (`test/foundry/fork/ethereum_main/uniswapV3/` and `test/foundry/fork/base_main/slipstream/`).
- In the worktree, install upstream for testing ONLY (temporary dependency), pinned to the commit above:
  - `forge install https://github.com/opengsn/gsn`
  - checkout commit `8e0c9ed23d9798b7384e8255054631c3cb414fdf`
- Do not keep the dependency after tests pass; remove the installed `lib/` entry and any related remappings.

## Files to Create/Modify

**New Files (suggested):**
- `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol`
- `test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol`
- `test/foundry/fork/ethereum_main/gsn/RecipientStub.sol`

**Modified Files (if needed):**
- `contracts/protocols/utils/gsn/forwarder/Forwarder.sol` (only if parity tests find a mismatch)

## Inventory Check

Before starting, verify:
- [x] `contracts/protocols/utils/gsn/forwarder/Forwarder.sol` exists and compiles
- [x] foundry has an Ethereum fork rpc alias configured
- [x] You have an `INFURA_KEY` for fork tests

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
