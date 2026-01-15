# Task CRANE-022: Rename EIP721_TYPE_HASH to EIP712_TYPE_HASH

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-005
**Worktree:** `fix/eip712-typehash-typo`
**Origin:** Code review suggestion from CRANE-005

---

## Description

The constant `EIP721_TYPE_HASH` should be renamed to `EIP712_TYPE_HASH`. The typo "721" vs "712" creates confusion with ERC-721 (NFT standard) when this constant is actually for EIP-712 typed data hashing.

(Created from code review of CRANE-005)

## Dependencies

- CRANE-005: Token Standards Review (parent task - Complete)

## User Stories

### US-CRANE-022.1: Fix Naming Typo

As a developer reading the codebase, I want constant names to accurately reflect their purpose so that I don't confuse EIP-712 (typed data) with ERC-721 (NFTs).

**Acceptance Criteria:**
- [ ] Constant renamed from `EIP721_TYPE_HASH` to `EIP712_TYPE_HASH`
- [ ] All usages updated
- [ ] Tests pass

## Technical Details

**Current Naming:**
- `contracts/constants/Constants.sol:91` defines `bytes32 constant EIP721_TYPE_HASH`

**Usages to update:**
- `contracts/constants/Constants.sol` (definition)
- `contracts/utils/cryptography/EIP712/EIP712Repo.sol` (line 14, 98)
- `test/foundry/spec/utils/cryptography/EIP712/EIP712Repo.t.sol`
- `test/foundry/spec/tokens/ERC20/ERC20Permit_Integration.t.sol`

## Files to Create/Modify

**Modified Files:**
- `contracts/constants/Constants.sol`
- `contracts/utils/cryptography/EIP712/EIP712Repo.sol`
- `test/foundry/spec/utils/cryptography/EIP712/EIP712Repo.t.sol`
- `test/foundry/spec/tokens/ERC20/ERC20Permit_Integration.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-005 is complete
- [ ] Search for all usages of `EIP721_TYPE_HASH`

## Completion Criteria

- [ ] All instances of `EIP721_TYPE_HASH` renamed to `EIP712_TYPE_HASH`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
