# Task CRANE-205: Add Uniswap V4 Ported Contract Parity Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-02
**Dependencies:** CRANE-152 (archived)
**Worktree:** `test/uniswap-v4-ported-parity`

---

## Description

Add Ethereum mainnet fork tests that compare Crane's ported Uniswap V4 contracts against the canonical deployed Uniswap V4 stack.

Repo constraints / clarifications:
- Existing Uniswap V4 fork tests in this repo are Ethereum-only; Base coverage is optional and should not be required for task completion.
- `V4Router.sol` in this repo is abstract, so router parity is out-of-scope unless a concrete router implementation is introduced.
- Uniswap V4 relies on transient storage (EIP-1153). Tests must run with an EVM version that supports it (use Cancun).
- Network constant names for V4 in `ETHEREUM_MAIN.sol` include typos; parity tests should reference the constants as-is (do not introduce new hardcoded addresses), and constants cleanup should be handled separately.

## Dependencies

- CRANE-152: Port and Verify Uniswap V4 Core + Periphery (archived)

## User Stories

### US-CRANE-205.1: Fork Base Extension for Local Stack Deployment

As a developer, I want V4 fork tests to deploy a local PoolManager alongside the fork so I can compare behavior.

**Acceptance Criteria:**
- [x] Extend `test/foundry/fork/ethereum_main/uniswapV4/TestBase_UniswapV4Fork.sol` (or add a new sibling TestBase) with helpers to deploy a local PoolManager used by parity tests
- [x] Fork gating: tests must skip when `INFURA_KEY` is unset
- [x] Mainnet addresses pulled from `contracts/constants/networks/ETHEREUM_MAIN.sol`

### US-CRANE-205.2: PoolManager State Parity

As a developer, I want PoolManager initialization and state reads to match between mainnet and local.

**Acceptance Criteria:**
- [x] Initialize a local pool and assert `PoolId` derivation logic matches the canonical formula
- [x] Compare `slot0`-style state for a chosen mainnet pool against expected values derived from on-chain reads (no address equality assumptions)

### US-CRANE-205.3: Swap / ModifyLiquidity Parity (Optional)

As a developer, I want core operations to behave the same, provided we can execute them safely in tests.

**Acceptance Criteria:**
- [x] If implemented, all state-changing operations must use the unlock callback pattern and validate deltas settle
- [x] Keep scope to a minimal single-pool scenario; do not require router parity

*Note: US-CRANE-205.3 tests are skipped in the fork context due to mainnet token transfer mechanics (WETH requires deposit/withdraw pattern). The unlock callback infrastructure is implemented and ready for use with mock tokens in a non-fork test environment.*

## Technical Details

### EVM Version Requirement

Tests must run with Cancun enabled:

`forge test --evm-version cancun --match-path "test/foundry/fork/ethereum_main/uniswapV4/**Ported**"`

### Directory Structure

```
test/foundry/fork/ethereum_main/uniswapV4/
├── TestBase_UniswapV4Fork.sol                 # existing; may be extended
└── UniswapV4PortedPoolManagerParity_Fork.t.sol
```

### Inventory Check

- [x] Existing fork base exists: `test/foundry/fork/ethereum_main/uniswapV4/TestBase_UniswapV4Fork.sol`
- [x] Ported V4 core exists and compiles (PoolManager)
- [x] `foundry.toml` includes `ethereum_mainnet_infura`

## Completion Criteria

- [x] Tests pass: `forge test --evm-version cancun --match-path "test/foundry/fork/ethereum_main/uniswapV4/**Ported**"`
- [x] Tests skip gracefully when `INFURA_KEY` is not set

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
