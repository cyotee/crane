# Task CRANE-170: Document DeployPermit2 Bytecode Source

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-150
**Worktree:** `docs/deploypermit2-docs`
**Origin:** Code review suggestion from CRANE-150

---

## Description

Add comment documenting the source and version of the hardcoded Permit2 bytecode in DeployPermit2.sol.

(Created from code review of CRANE-150)

## Dependencies

- CRANE-150: Verify Permit2 Contract Port Completeness (Complete)

## User Stories

### US-CRANE-170.1: Document Bytecode Source

As a developer, I want to know where the hardcoded Permit2 bytecode came from so that I can verify its authenticity and understand maintenance implications.

**Acceptance Criteria:**
- [ ] Add NatSpec comment documenting:
  - Source repository and commit hash
  - Solidity compiler version used
  - Compilation settings (viaIR, optimizer runs)
  - Canonical deployment address
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/utils/permit2/test/utils/DeployPermit2.sol`

## Example Documentation

```solidity
/// @notice Deploys Permit2 to the canonical address using vm.etch
/// @dev Bytecode source:
///   - Repository: https://github.com/Uniswap/permit2
///   - Commit: [commit hash]
///   - Compiler: Solc 0.8.17 with viaIR and 1000000 optimizer runs
///   - Canonical address: 0x000000000022D473030F116dDEE9F6B43aC78BA3
```

## Inventory Check

Before starting, verify:
- [x] CRANE-150 is complete
- [ ] DeployPermit2.sol exists at expected path

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
