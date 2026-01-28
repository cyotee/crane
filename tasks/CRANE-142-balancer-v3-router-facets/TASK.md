# Task CRANE-142: Refactor Balancer V3 Router Contracts as Diamond Facets

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Vault facets must be complete first)
**Worktree:** `feature/balancer-v3-router-facets`

---

## Description

Refactor the Balancer V3 Router contracts (Router, BatchRouter, BatchRouterHooks, CompositeLiquidityRouter, BufferRouter) to use the Diamond Pattern (EIP-2535) to reduce bytecode sizes below 24KB deployment limits.

The Router contracts interact heavily with the Vault and must work correctly with the Diamond Vault from CRANE-141.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Router requires deployed Vault to function

## User Stories

### US-CRANE-142.1: Router Diamond Setup

As a deployer, I want a Diamond proxy for Router functionality so that I can deploy the swap router within contract size limits.

**Acceptance Criteria:**
- [ ] Router Diamond proxy at `contracts/protocols/dexes/balancer/v3/router/BalancerV3RouterDiamond.sol`
- [ ] Storage layout matches original Router contracts
- [ ] Works with Diamond Vault from CRANE-141

### US-CRANE-142.2: Core Router Facets

As a user, I want swap functionality available so that I can execute trades through the Router.

**Acceptance Criteria:**
- [ ] Single swap functions work
- [ ] Multi-hop swap functions work
- [ ] Deadline enforcement works
- [ ] Slippage protection works
- [ ] All IRouter interface functions accessible

### US-CRANE-142.3: BatchRouter Facets

As a user, I want batch operations so that I can execute multiple operations in one transaction.

**Acceptance Criteria:**
- [ ] Batch swap functions work
- [ ] BatchRouterHooks functionality integrated
- [ ] Gas-efficient batch execution

### US-CRANE-142.4: CompositeLiquidityRouter Facets

As a user, I want composite liquidity operations so that I can add/remove liquidity with wrapped tokens.

**Acceptance Criteria:**
- [ ] Add liquidity with unwrapping works
- [ ] Remove liquidity with wrapping works
- [ ] Nested pool operations work

### US-CRANE-142.5: BufferRouter Facets

As a user, I want buffer operations so that I can interact with ERC4626 buffers.

**Acceptance Criteria:**
- [ ] Buffer wrap/unwrap functions work
- [ ] Integration with Vault buffers verified

### US-CRANE-142.6: Test Suite

As a developer, I want comprehensive tests verifying Router Diamond works identically to original.

**Acceptance Criteria:**
- [ ] Fork Balancer's Router tests adapted for Diamond
- [ ] All original test cases pass
- [ ] Integration with Diamond Vault from CRANE-141
- [ ] Fork test comparing vs mainnet behavior

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── router/
│   ├── BalancerV3RouterDiamond.sol       # Diamond proxy
│   ├── BalancerV3RouterStorage.sol       # Shared storage
│   ├── facets/
│   │   ├── RouterSwapFacet.sol           # single/multi swap
│   │   ├── RouterLiquidityFacet.sol      # add/remove liquidity
│   │   ├── BatchRouterFacet.sol          # batch operations
│   │   ├── BatchRouterHooksFacet.sol     # batch hooks
│   │   ├── CompositeLiquidityFacet.sol   # composite operations
│   │   ├── BufferRouterFacet.sol         # buffer operations
│   │   └── ... (additional as needed)
│   └── lib/
│       └── (extracted libraries if needed)
```

### Key Contracts to Refactor

| Contract | Size | Priority |
|----------|------|----------|
| Router.sol | ~28KB source | High |
| BatchRouterHooks.sol | ~32KB source | High |
| CompositeLiquidityRouterHooks.sol | ~35KB source | High |
| BatchRouter.sol | ~6KB source | Medium |
| BufferRouter.sol | ~10KB source | Medium |
| RouterCommon.sol | ~14KB source | Shared base |

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/router/BalancerV3RouterDiamond.sol`
- `contracts/protocols/dexes/balancer/v3/router/facets/*.sol`
- `test/foundry/protocols/balancer/v3/router/*.t.sol`

**Reference Files:**
- `lib/balancer-v3-monorepo/pkg/vault/contracts/Router.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/BatchRouter*.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/CompositeLiquidityRouter*.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/BufferRouter.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-141 (Vault facets) is complete
- [ ] Diamond Vault deploys and works
- [ ] Understand Router's interaction pattern with Vault

## Completion Criteria

- [ ] All Router facets compile to <24KB each
- [ ] Router Diamond deploys successfully
- [ ] All swap, batch, and liquidity functions work
- [ ] Integration with Diamond Vault verified
- [ ] Tests pass
- [ ] Fork test verifies identical behavior

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
