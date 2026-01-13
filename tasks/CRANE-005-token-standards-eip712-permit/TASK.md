# Task CRANE-005: Review — Token Standards (ERC20, Permit, EIP-712)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-token-standards-eip712-permit`

---

## Description

Review Crane token facets and cryptography utilities for signature correctness and coverage (domain separation, replay protections, chainId behaviors).

## Dependencies

- None

## User Stories

### US-CRANE-005.1: Produce a Token Standards Correctness Memo

As a maintainer, I want a clear summary of signature and domain invariants so that token integrations are safe.

**Acceptance Criteria:**
- [ ] Memo documents domain separation and replay protections
- [ ] Memo lists missing tests
- [ ] Memo identifies any EIP compliance gaps (EIP-712, ERC-2612, ERC-5267)

## Technical Details

Focus areas:

**ERC20 Facet:**
- Standard compliance (transfer, approve, allowance)
- Event emission correctness
- Edge cases (zero transfers, self-transfers)

**Permit (ERC-2612):**
- Signature validation
- Nonce management
- Deadline enforcement
- Domain separator calculation

**EIP-712:**
- Type hash correctness
- Domain separator components (name, version, chainId, verifyingContract)
- Cross-chain behavior (chainId changes)

**ERC-5267:**
- Domain fields exposure
- Immutable vs mutable domain components

## Files to Create/Modify

**New Files:**
- `docs/review/token-standards.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/tokens/ERC20/`
- [ ] Review permit-related contracts
- [ ] Review EIP-712 utilities
- [ ] Review `contracts/tokens/ERC20/TestBase_ERC20.sol`
- [ ] Review `contracts/tokens/ERC20/TestBase_ERC20Permit.sol`

## Completion Criteria

- [ ] Memo exists at `docs/review/token-standards.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
