# Task CRANE-204: Add Uniswap V3 Ported Contract Parity Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-02
**Dependencies:** CRANE-151 (archived)
**Worktree:** `test/uniswap-v3-ported-parity`

---

## Description

Add fork tests that compare behavior of Crane's ported Uniswap V3 stack against canonical mainnet Uniswap V3 deployments.

Repo constraints / clarifications:
- Existing Uniswap V3 fork tests in this repo are Ethereum-only; Base coverage is optional and should not be required for task completion.
- Fork tests must skip when `INFURA_KEY` is not set and use rpc aliases from `foundry.toml`.
- Do not assert pool address equality between mainnet and local deployments: the ported V3 init code hash can differ, so address determinism is only meaningful within the same stack.
- Use `contracts/constants/networks/ETHEREUM_MAIN.sol` (and `BASE_MAIN.sol` if Base coverage is added).

## Dependencies

- CRANE-151: Port and Verify Uniswap V3 Core + Periphery (archived)

## User Stories

### US-CRANE-204.1: Extend Fork Base for Local Stack Deployment

As a developer, I want V3 fork tests to deploy a local V3 stack alongside the fork so I can compare behavior.

**Acceptance Criteria:**
- [x] Update `test/foundry/fork/ethereum_main/uniswapV3/TestBase_UniswapV3Fork.sol` (or add a new sibling TestBase) with helpers to deploy a local V3 stack used by parity tests
- [x] Fork gating: tests must skip when `INFURA_KEY` is unset
- [x] Use mainnet addresses from `ETHEREUM_MAIN` (factory/router/quoter/nft position manager)

### US-CRANE-204.2: Core Pool Swap Parity

As a developer, I want swaps on a locally deployed V3 pool to match swaps on a comparable mainnet V3 pool.

**Acceptance Criteria:**
- [x] Compare swap outputs for identical swap params (same fee tier) between:
  - a chosen mainnet pool with existing liquidity, and
  - a locally deployed pool initialized + seeded to a comparable state (as close as practical)
- [x] Validate `pool.swap()` (direct) parity for at least two swap directions and multiple trade sizes

### US-CRANE-204.3: Quoter Parity (Optional)

As a developer, I want our local quoter results to match mainnet quoter results.

**Acceptance Criteria:**
- [ ] If included, compare QuoterV2 quote outputs against swap execution outputs for both mainnet and local pool

## Technical Details

### Directory Structure

Prefer keeping parity tests next to existing fork tests:

```
test/foundry/fork/ethereum_main/uniswapV3/
├── TestBase_UniswapV3Fork.sol              # existing; may be extended
├── UniswapV3PortedPoolParity_Fork.t.sol    # new
└── UniswapV3PortedSwapParity_Fork.t.sol    # new (or merge into one file)
```

### Inventory Check

- [x] Existing fork base exists: `test/foundry/fork/ethereum_main/uniswapV3/TestBase_UniswapV3Fork.sol`
- [x] Ported V3 contracts exist and compile (factory/pool/periphery as applicable)
- [x] `contracts/constants/networks/ETHEREUM_MAIN.sol` has V3 addresses
- [x] `foundry.toml` includes `ethereum_mainnet_infura`

## Completion Criteria

- [x] Tests pass: `forge test --match-path "test/foundry/fork/ethereum_main/uniswapV3/**Ported**"`
- [x] Tests skip gracefully when `INFURA_KEY` is not set

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
