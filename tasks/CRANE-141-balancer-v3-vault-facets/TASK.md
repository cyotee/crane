# Task CRANE-141: Refactor Balancer V3 Vault as Diamond Facets

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/balancer-v3-vault-facets`

---

## Description

Refactor the Balancer V3 Vault (pkg/vault) contracts to use the Diamond Pattern (EIP-2535) to reduce individual contract bytecode sizes below the 24KB deployment limit. The original Vault.sol is ~82KB of source (~1600 lines) and compiles to bytecode that exceeds deployment limits even with optimizer settings.

The refactored contracts must maintain 100% interface compatibility with the original Balancer V3 interfaces (IVaultMain, IVaultExtension, IVaultAdmin) so existing frontends and integrations work unchanged.

Target environment is post-Cancun EVM chains (can use transient storage).

## Dependencies

None - this is the foundation task for Balancer V3 Lite deployment.

## User Stories

### US-CRANE-141.1: Diamond Proxy Setup

As a deployer, I want a Diamond proxy that routes Vault function calls to appropriate facets so that I can deploy Balancer V3 functionality within contract size limits.

**Acceptance Criteria:**
- [ ] Diamond proxy contract created at `contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultDiamond.sol`
- [ ] Storage layout matches original Balancer V3 Vault (VaultStorage.sol)
- [ ] All `using X for Y` directives available to facets via inheritance
- [ ] EIP-2535 DiamondCut, DiamondLoupe functions implemented
- [ ] Proxy fallback correctly delegates to facets based on selector

### US-CRANE-141.2: Vault Facet Implementation

As a deployer, I want the Vault functionality split into granular facets so that each facet compiles to deployable bytecode (<24KB).

**Acceptance Criteria:**
- [ ] Agent determines optimal facet split based on bytecode analysis
- [ ] Each facet stays under 24KB compiled bytecode
- [ ] All IVaultMain functions accessible through Diamond proxy
- [ ] All IVaultExtension functions accessible through Diamond proxy
- [ ] All IVaultAdmin functions accessible through Diamond proxy
- [ ] Internal function sharing handled via Diamond storage or libraries

### US-CRANE-141.3: VaultExtension Facet(s)

As a deployer, I want VaultExtension functionality available through facets so that pool registration and query functions work.

**Acceptance Criteria:**
- [ ] Pool registration functions (registerPool) work through proxy
- [ ] Query functions work through proxy
- [ ] Rate provider functions work through proxy
- [ ] All VaultExtension events emitted correctly

### US-CRANE-141.4: VaultAdmin Facet(s)

As a deployer, I want VaultAdmin functionality available through facets so that administrative functions work.

**Acceptance Criteria:**
- [ ] Pause/unpause functions work through proxy
- [ ] Fee controller functions work through proxy
- [ ] Buffer management functions work through proxy
- [ ] Authentication/authorization preserved

### US-CRANE-141.5: ProtocolFeeController Refactor

As a deployer, I want the ProtocolFeeController deployable so that fee management works.

**Acceptance Criteria:**
- [ ] ProtocolFeeController compiles to <24KB (or split if needed)
- [ ] All fee functions work correctly
- [ ] Integration with Vault facets verified

### US-CRANE-141.6: Test Suite

As a developer, I want comprehensive tests verifying the Diamond Vault behaves identically to the original.

**Acceptance Criteria:**
- [ ] Fork Balancer's Vault tests adapted for Diamond architecture
- [ ] All original test cases pass
- [ ] Integration test comparing Diamond Vault vs mainnet Vault behavior
- [ ] Gas comparison tests (Diamond overhead acceptable)
- [ ] Facet upgrade/replacement tests

## Technical Details

### File Structure

```
contracts/protocols/dexes/balancer/v3/
├── vault/
│   ├── BalancerV3VaultDiamond.sol       # Diamond proxy
│   ├── BalancerV3VaultStorage.sol       # Shared storage layout
│   ├── facets/
│   │   ├── VaultTransientFacet.sol      # unlock, settle, transient accounting
│   │   ├── VaultSwapFacet.sol           # swap functions
│   │   ├── VaultLiquidityFacet.sol      # add/remove liquidity
│   │   ├── VaultBufferFacet.sol         # buffer operations
│   │   ├── VaultQueryFacet.sol          # query/view functions
│   │   ├── VaultExtensionFacet.sol      # pool registration, ERC4626
│   │   ├── VaultAdminFacet.sol          # admin/permissioned functions
│   │   └── ... (additional facets as needed)
│   └── lib/
│       └── (extracted libraries if needed)
└── interfaces/
    └── (re-export Balancer interfaces for convenience)
```

### Key Technical Challenges

1. **Storage Layout**: Must exactly match VaultStorage.sol layout
2. **Transient Storage**: Balancer uses EIP-1153 transient storage extensively
3. **Internal Function Sharing**: Functions like `_loadPoolDataUpdatingBalancesAndYieldFees` are used across multiple entry points
4. **Modifiers**: `transient()`, `onlyVaultDelegateCall()`, etc. need careful handling
5. **Proxy Delegation**: Original Vault uses OpenZeppelin Proxy for extensions; Diamond pattern replaces this

### Bytecode Analysis Required

Before splitting, compile original contracts and measure:
- Vault.sol bytecode size
- VaultExtension.sol bytecode size
- VaultAdmin.sol bytecode size
- ProtocolFeeController.sol bytecode size

Document current sizes and target sizes in implementation.

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultDiamond.sol`
- `contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultStorage.sol`
- `contracts/protocols/dexes/balancer/v3/vault/facets/*.sol` (multiple)
- `test/foundry/protocols/balancer/v3/vault/*.t.sol` (test files)

**Reference Files (read-only):**
- `lib/balancer-v3-monorepo/pkg/vault/contracts/Vault.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/VaultExtension.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/VaultAdmin.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/VaultStorage.sol`
- `lib/balancer-v3-monorepo/pkg/vault/contracts/VaultCommon.sol`

## Inventory Check

Before starting, verify:
- [ ] Balancer V3 monorepo submodule is at lib/balancer-v3-monorepo
- [ ] Can compile original Balancer contracts with forge
- [ ] Understand existing Crane Diamond implementation in src/diamond/
- [ ] Have access to Balancer V3 deployed addresses for fork testing

## Completion Criteria

- [ ] All Vault facets compile to <24KB each
- [ ] Diamond proxy deploys successfully
- [ ] All IVaultMain, IVaultExtension, IVaultAdmin functions work
- [ ] Adapted test suite passes
- [ ] Fork test against mainnet verifies identical behavior
- [ ] Build succeeds with `forge build`
- [ ] Tests pass with `forge test`

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
