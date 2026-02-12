# Task CRANE-221: Complete Uniswap V4 Port Verification with Base Fork Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-04
**Dependencies:** CRANE-152 (archived), CRANE-205 (archived)
**Worktree:** `feature/v4-port-complete-verification`

---

## Description

Comprehensive verification that the Uniswap V4 port is complete and can serve as a drop-in replacement for testing. This task adds Base mainnet fork tests alongside the existing Ethereum mainnet tests, verifies interface completeness (no hidden submodule dependencies), and enables behavioral tests (swap/liquidity operations) that were skipped in the initial parity tests. Success is confirmed when all tests pass, no imports reference v4-core/v4-periphery submodules, and build succeeds without V4 remappings.

## Dependencies

- CRANE-152: Port and Verify Uniswap V4 Core + Periphery (archived - complete)
- CRANE-205: Add Uniswap V4 Ported Contract Parity Tests (archived - complete)

## User Stories

### US-CRANE-221.1: Add Base Mainnet Fork Tests

As a developer, I want V4 parity tests running against Base mainnet so that I verify cross-chain compatibility.

**Acceptance Criteria:**
- [ ] Create `test/foundry/fork/base_main/uniswapV4/` directory
- [ ] Port `TestBase_UniswapV4Fork.sol` structure for Base mainnet
- [ ] Add Base network constants to test base (from `BASE_MAIN.sol`)
- [ ] Create `UniswapV4PortedPoolManagerParity_BaseFork.t.sol`
- [ ] Tests include PoolId derivation parity checks
- [ ] Tests include pool initialization state verification
- [ ] Tests skip gracefully when `INFURA_KEY` or Base RPC is unavailable
- [ ] Tests pass: `forge test --evm-version cancun --match-path "test/foundry/fork/base_main/uniswapV4/**"`

### US-CRANE-221.2: Verify Interface Completeness

As a developer, I want confirmation that all V4 interfaces are ported with no hidden submodule dependencies.

**Acceptance Criteria:**
- [ ] `grep -r "lib/v4-core" contracts/` returns no results
- [ ] `grep -r "lib/v4-periphery" contracts/` returns no results
- [ ] All imports in `contracts/protocols/dexes/uniswap/v4/` resolve to local files
- [ ] Compare ported interface list against original v4-core/v4-periphery interfaces
- [ ] Document any intentionally omitted interfaces with justification
- [ ] `forge build` succeeds after removing V4 remappings from `foundry.toml`

### US-CRANE-221.3: Enable Behavioral Tests (Swap/Liquidity)

As a developer, I want swap and liquidity modification tests to execute (not skip) so that behavioral parity is verified.

**Acceptance Criteria:**
- [ ] Add mock token deployment to test base for behavioral tests
- [ ] Implement `test_LocalPoolManager_ModifyLiquidityViaCallback` with mock tokens (not skipped)
- [ ] Implement `test_LocalPoolManager_SwapViaCallback` with mock tokens (not skipped)
- [ ] Verify delta settlement logic works correctly
- [ ] Tests execute and pass (not skipped)
- [ ] Add comparison assertions between local and mainnet behavior where applicable

### US-CRANE-221.4: Complete CRANE-200 Scope

As a developer, I want the remapping removal verified alongside the comprehensive verification.

**Acceptance Criteria:**
- [ ] Remove `v4-core` remappings from `foundry.toml` and `remappings.txt`
- [ ] Remove `v4-periphery` remappings from `foundry.toml` and `remappings.txt`
- [ ] Verify `permit2/` resolves to Crane-owned sources
- [ ] Verify `solmate/` resolves to Crane-owned sources (or is unused)
- [ ] `forge build` succeeds without V4 remappings
- [ ] All V4 spec tests pass
- [ ] All V4 fork tests pass (Ethereum + Base)

### US-CRANE-221.5: Update CRANE-189 Prerequisites

As a developer, I want CRANE-189 (Remove v4 submodules) to be unblocked after this task completes.

**Acceptance Criteria:**
- [ ] All acceptance criteria from US-CRANE-221.1 through US-CRANE-221.4 met
- [ ] CRANE-189 can proceed with submodule removal
- [ ] Document any caveats or known limitations in this task's REVIEW.md

## Technical Details

### Obtaining Original Uniswap V4 Source Code

The agent **must** clone the original upstream Uniswap V4 repositories to use as a reference for interface completeness verification and behavioral comparison. Clone these into a temporary directory (not into the project tree):

```bash
# Clone into scratchpad/temp directory for comparison
SCRATCH=$(mktemp -d)
git clone https://github.com/Uniswap/v4-core.git "$SCRATCH/v4-core"
git clone https://github.com/Uniswap/v4-periphery.git "$SCRATCH/v4-periphery"
```

**Upstream Repos:**
- **v4-core:** `https://github.com/Uniswap/v4-core.git` — Contains PoolManager, libraries (TickMath, SwapMath, etc.), and core interfaces
- **v4-periphery:** `https://github.com/Uniswap/v4-periphery.git` — Contains PositionManager, Quoter, StateView, and periphery interfaces

Use these cloned repos to:
1. Compare ported interface lists against originals (US-CRANE-221.2)
2. Verify no interfaces or functions were missed during porting
3. Cross-reference function signatures and event/error definitions
4. Document any intentional omissions with justification

After verification is complete, the temporary clones can be deleted.

### Directory Structure

```
test/foundry/fork/
├── ethereum_main/
│   └── uniswapV4/
│       ├── TestBase_UniswapV4Fork.sol            # Existing
│       ├── UniswapV4PortedPoolManagerParity_Fork.t.sol  # Existing
│       └── ...
└── base_main/
    └── uniswapV4/
        ├── TestBase_UniswapV4BaseFork.sol        # NEW
        └── UniswapV4PortedPoolManagerParity_BaseFork.t.sol  # NEW
```

### Base Mainnet V4 Addresses

From `contracts/constants/networks/BASE_MAIN.sol`:
- `UNSWAP_V4_POOL_MNANAGER`: 0x498581fF718922c3f8e6A244956aF099B2652b2b
- `UNSWAP_V4_POSITION_DESCRIPTOR`: 0x25D093633990DC94BeDEeD76C8F3CDaa75f3E7D5
- `UNSWAP_V4_PPOSITION_MANAGER`: 0x7C5f5A4bBd8fD63184577525326123B519429bDc
- `UNSWAP_V4_QUOTER`: 0x0d5e0F971ED27FBfF6c2837bf31316121532048D
- `UNSWAP_V4_STATE_VIEW`: 0xA3c0c9b65baD0b08107Aa264b0f3dB444b867A71

### Mock Token Strategy for Behavioral Tests

The existing tests skip swap/liquidity operations because mainnet tokens (WETH/USDC) have complex transfer mechanics. To enable these tests:

1. Deploy mock ERC20 tokens in test setup
2. Use mock tokens for local PoolManager operations
3. Compare state changes against expected V4 behavior
4. Do not attempt to replicate mainnet token balances (out of scope)

### Remapping Verification Commands

```bash
# Verify no V4 submodule references
grep -r "lib/v4-core" contracts/ test/ --include="*.sol"
grep -r "lib/v4-periphery" contracts/ test/ --include="*.sol"

# Check remappings
grep -E "v4-(core|periphery)" foundry.toml remappings.txt

# Build without V4 remappings
forge build

# Run V4 tests
forge test --evm-version cancun --match-path "test/foundry/spec/protocols/dexes/uniswap/v4/**"
forge test --evm-version cancun --match-path "test/foundry/fork/ethereum_main/uniswapV4/**"
forge test --evm-version cancun --match-path "test/foundry/fork/base_main/uniswapV4/**"
```

## Files to Create/Modify

**New Files:**
- `test/foundry/fork/base_main/uniswapV4/TestBase_UniswapV4BaseFork.sol`
- `test/foundry/fork/base_main/uniswapV4/UniswapV4PortedPoolManagerParity_BaseFork.t.sol`

**Modified Files:**
- `test/foundry/fork/ethereum_main/uniswapV4/UniswapV4PortedPoolManagerParity_Fork.t.sol` - Enable behavioral tests
- `test/foundry/fork/ethereum_main/uniswapV4/TestBase_UniswapV4Fork.sol` - Add mock token helpers
- `foundry.toml` - Remove V4 remappings
- `remappings.txt` - Remove V4 remappings (if present)

**Verification Files:**
- Create checklist of all V4 interfaces comparing ported vs submodule

## Inventory Check

Before starting, verify:
- [ ] Can clone upstream repos: `https://github.com/Uniswap/v4-core.git` and `https://github.com/Uniswap/v4-periphery.git`
- [ ] Ethereum mainnet fork tests exist and pass
- [ ] Ported V4 contracts compile
- [ ] V4 addresses exist in `BASE_MAIN.sol`
- [ ] Mock token infrastructure exists (MockERC20)
- [ ] Current V4 remappings in foundry.toml

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Base mainnet fork tests pass
- [ ] Ethereum mainnet fork tests pass (including new behavioral tests)
- [ ] No V4 submodule imports remain
- [ ] Build succeeds without V4 remappings
- [ ] CRANE-200 can be marked complete
- [ ] CRANE-189 is unblocked

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
