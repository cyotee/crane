# Task CRANE-218: Port Balancer V3 Test Mocks and Tokens to Crane

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-04
**Dependencies:** None
**Worktree:** `feature/balancer-v3-test-mock-port`

---

## Description

Complete the port of Balancer V3 test utilities from the monorepo to Crane-local implementations. This eliminates all `@balancer-labs/**/contracts/test/**` and `@balancer-labs/**/test/foundry/utils/**` imports from Crane, enabling eventual removal of the `lib/reclamm` submodule. Create fork tests against Ethereum mainnet to prove behavioral equivalence between ported code and on-chain Balancer V3 contracts.

**Context:** Previous work (tracked in IndexedEx's `BALANCER_V3_TEST_DEPS_NOTES.md`) ported many mocks but left test tokens and vault mocks with Balancer imports. This task completes that work within Crane.

## Dependencies

None

## User Stories

### US-CRANE-218.1: Port Test Tokens to Crane

As a developer, I want all Balancer test token mocks ported to Crane so that `BaseTest.sol` has no external test dependencies.

**Acceptance Criteria:**
- [ ] Port `ERC20TestToken` to `contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol`
- [ ] Port `WETHTestToken` to `contracts/protocols/dexes/balancer/v3/test/mocks/WETHTestToken.sol`
- [ ] Port `ERC4626TestToken` to `contracts/protocols/dexes/balancer/v3/test/mocks/ERC4626TestToken.sol`
- [ ] Update `contracts/protocols/dexes/balancer/v3/test/utils/BaseTest.sol` imports to use `@crane/...` paths
- [ ] Verify no `@balancer-labs/.../contracts/test/` imports remain in `BaseTest.sol`

### US-CRANE-218.2: Port Vault Mocks to Crane

As a developer, I want all Balancer Vault mocks ported to Crane so that `VaultContractsDeployer.sol` has no external test dependencies.

**Acceptance Criteria:**
- [ ] Port `VaultMock` to `contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol`
- [ ] Port `VaultAdminMock` to `contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol`
- [ ] Port `VaultExtensionMock` to `contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol`
- [ ] Update `contracts/protocols/dexes/balancer/v3/test/utils/VaultContractsDeployer.sol` imports to use `@crane/...` paths
- [ ] Ensure ported vault mocks import from Crane-local interface mocks (`test/mocks/interfaces/`)

### US-CRANE-218.3: Port WeightedPoolContractsDeployer

As a developer, I want the WeightedPoolContractsDeployer ported so that `TestBase_BalancerV3_8020WeightedPool.sol` has no external test dependencies.

**Acceptance Criteria:**
- [ ] Create `contracts/protocols/dexes/balancer/v3/test/utils/WeightedPoolContractsDeployer.sol`
- [ ] Port minimal functions: `deployWeightedPool8020Factory` and related helpers
- [ ] Update `contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol` to use Crane-local deployer
- [ ] Verify imports use `@crane/...` remappings

### US-CRANE-218.4: Verify All Balancer Test Imports Removed

As a developer, I want verification that no Balancer test imports remain in Crane.

**Acceptance Criteria:**
- [ ] `rg "@balancer-labs/.*/contracts/test" contracts/` returns no results
- [ ] `rg "@balancer-labs/.*/test/foundry/utils" contracts/` returns no results
- [ ] `forge build` succeeds without errors
- [ ] Existing Crane tests pass with `forge test`

### US-CRANE-218.5: Create Fork Tests for Behavioral Equivalence

As a developer, I want fork tests proving ported test mocks behave identically to Balancer's originals.

**Acceptance Criteria:**
- [ ] Create `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol`
- [ ] Tests fork Ethereum mainnet at a recent block
- [ ] Tests compare: ERC20TestToken mint/burn, VaultMock operations, WeightedPool factory deployment
- [ ] Tests pass with acceptable tolerance (typically 0 wei for mocks, 1 wei for math)

## Technical Details

### Files to Port

**Source locations (in `lib/reclamm/lib/balancer-v3-monorepo/`):**

| Balancer Path | Crane Destination |
|--------------|-------------------|
| `pkg/solidity-utils/contracts/test/ERC20TestToken.sol` | `contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol` |
| `pkg/solidity-utils/contracts/test/WETHTestToken.sol` | `contracts/protocols/dexes/balancer/v3/test/mocks/WETHTestToken.sol` |
| `pkg/solidity-utils/contracts/test/ERC4626TestToken.sol` | `contracts/protocols/dexes/balancer/v3/test/mocks/ERC4626TestToken.sol` |
| `pkg/vault/contracts/test/VaultMock.sol` | `contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol` |
| `pkg/vault/contracts/test/VaultAdminMock.sol` | `contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol` |
| `pkg/vault/contracts/test/VaultExtensionMock.sol` | `contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol` |
| `pkg/pool-weighted/test/foundry/utils/WeightedPoolContractsDeployer.sol` | `contracts/protocols/dexes/balancer/v3/test/utils/WeightedPoolContractsDeployer.sol` |

### Already Ported (Do Not Re-port)

These files already exist in Crane's `contracts/protocols/dexes/balancer/v3/test/`:

**Mocks:**
- `ArrayHelpers.sol`
- `RateProviderMock.sol`
- `PoolMock.sol`
- `PoolFactoryMock.sol`
- `PoolHooksMock.sol`
- `IVaultMock.sol`
- `BasicAuthorizerMock.sol`
- `RouterMock.sol`
- `BatchRouterMock.sol`
- `CompositeLiquidityRouterMock.sol`
- `BufferRouterMock.sol`
- `InputHelpersMock.sol`

**Interface Mocks (in `mocks/interfaces/`):**
- `IVaultAdminMock.sol`
- `IVaultExtensionMock.sol`
- `IVaultStorageMock.sol`
- `IVaultMainMock.sol`

**Utils:**
- `BaseTest.sol` (structure exists, imports need updating)
- `VaultContractsDeployer.sol` (structure exists, imports need updating)

### Import Update Pattern

When updating imports, replace:
```solidity
// OLD
import {ERC20TestToken} from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";

// NEW
import {ERC20TestToken} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol";
```

### Constraint

Do NOT enable `via_ir` in forge config. All contracts must compile without IR.

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/test/mocks/ERC20TestToken.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/WETHTestToken.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/ERC4626TestToken.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/VaultMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/VaultAdminMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/mocks/VaultExtensionMock.sol`
- `contracts/protocols/dexes/balancer/v3/test/utils/WeightedPoolContractsDeployer.sol`
- `test/foundry/fork/ethereum/balancer/v3/BalancerV3TestMock_Parity.t.sol`

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/test/utils/BaseTest.sol` - update imports
- `contracts/protocols/dexes/balancer/v3/test/utils/VaultContractsDeployer.sol` - update imports
- `contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol` - update imports

## Inventory Check

Before starting, verify:
- [ ] Balancer V3 monorepo exists at `lib/reclamm/lib/balancer-v3-monorepo/`
- [ ] Source files to port exist in expected Balancer locations
- [ ] Crane's existing test mocks compile with `forge build`
- [ ] ETH mainnet RPC is available for fork tests

## Handy Commands

```bash
# Find remaining Balancer test imports in Crane
rg "@balancer-labs/.*/contracts/test" contracts/
rg "@balancer-labs/.*/test/foundry/utils" contracts/

# Check current VaultContractsDeployer imports
cat contracts/protocols/dexes/balancer/v3/test/utils/VaultContractsDeployer.sol | grep "import"

# Check current BaseTest imports
cat contracts/protocols/dexes/balancer/v3/test/utils/BaseTest.sol | grep "import"

# Build to verify compilation
forge build

# Run existing tests
forge test --match-path "test/foundry/**"

# Run fork tests (after creating them)
forge test --match-path "test/foundry/fork/ethereum/balancer/v3/*" --fork-url $ETH_RPC_URL
```

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] No `@balancer-labs/.*/contracts/test` imports in Crane `contracts/` directory
- [ ] No `@balancer-labs/.*/test/foundry/utils` imports in Crane `contracts/` directory
- [ ] `forge build` succeeds
- [ ] `forge test` passes
- [ ] Fork parity tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
