# Task CRANE-202: Add Uniswap V2 Fork Comparison Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-02
**Dependencies:** CRANE-007 (archived)
**Worktree:** `test/uniswap-v2-fork-comparison`

---

## Description

Add fork tests on Ethereum and Base that validate Crane's Uniswap V2 stubs and math utilities against real Uniswap V2 deployments.

The tests should follow existing fork conventions in this repo:
- use Foundry RPC aliases from `foundry.toml` (e.g. `ethereum_mainnet_infura`, `base_mainnet_infura`)
- skip gracefully when `INFURA_KEY` is not set
- use network constants from `contracts/constants/networks/ETHEREUM_MAIN.sol` and `contracts/constants/networks/BASE_MAIN.sol` (no hardcoded addresses)

Scope note: do not require "mainnet vs local" pool address equality; this task is about behavioral parity (amounts/reverts/events where applicable).

## Dependencies

- CRANE-007: Uniswap V2 Utilities Review (archived - validated UniswapV2Utils and ConstProdUtils)

## User Stories

### US-CRANE-202.1: Fork Test Base

As a developer, I want a Uniswap V2 fork TestBase so tests share setup and are reproducible.

**Acceptance Criteria:**
- [x] Create `test/foundry/fork/ethereum_main/uniswapV2/TestBase_UniswapV2Fork.sol`
- [x] Create `test/foundry/fork/base_main/uniswapV2/TestBase_UniswapV2ForkBase.sol`
- [x] Fork gating: tests must skip when `INFURA_KEY` is unset
- [x] Forks use `vm.createSelectFork("ethereum_mainnet_infura", blockNumber)` and `vm.createSelectFork("base_mainnet_infura", blockNumber)`
- [x] Mainnet addresses come from `ETHEREUM_MAIN.UNISWAP_V2_FACTORY`, `ETHEREUM_MAIN.UNISWAP_V2_ROUTER`, `BASE_MAIN.UNISWAP_V2_FACTORY`, `BASE_MAIN.UNISWAP_V2_ROUTER`

### US-CRANE-202.2: Quote/Math Parity (Core Deliverable)

As a developer, I want quote utilities to match on-chain router behavior so integration tests can rely on them.

**Acceptance Criteria:**
- [x] On an existing mainnet pair with nonzero reserves, verify `getAmountsOut` and `getAmountsIn` align with `ConstProdUtils._saleQuote()` / `ConstProdUtils._purchaseQuote()` (same fee basis as Uniswap V2)
- [x] Include tests for at least: small amount-in, medium amount-in, and near-reserve-bound amount-in
- [x] Validate expected reverts for invalid inputs (e.g. zero amount, empty path) match Uniswap V2 behavior

### US-CRANE-202.3: Stub Sanity (Local) Tests

As a developer, I want to ensure our local UniV2 stubs behave like Uniswap V2 for the primitives we depend on.

**Acceptance Criteria:**
- [x] Deploy `UniV2Factory` + `UniV2Router02` stubs locally (not on a fork)
- [x] Create a pair, seed liquidity, and assert swap output equals `ConstProdUtils` quote
- [x] Include a 18/18 and an 18/6 token decimal combination using `ERC20PermitMintableStub`

## Technical Details

### Directory Structure

```
test/foundry/fork/
├── ethereum_main/
│   └── uniswapV2/
│       ├── TestBase_UniswapV2Fork.sol
│       └── UniswapV2Utils_Fork.t.sol
└── base_main/
    └── uniswapV2/
        ├── TestBase_UniswapV2ForkBase.sol
        └── UniswapV2Utils_ForkBase.t.sol

test/foundry/spec/
└── protocols/
    └── dexes/
        └── uniswap/
            └── v2/
                └── UniswapV2Stubs_Sanity.t.sol
```

### Inventory Check

- [x] `contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol` exists
- [x] `contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol` exists
- [x] `contracts/utils/math/ConstProdUtils.sol` exists
- [x] `contracts/utils/math/UniswapV2Utils.sol` exists (if used)
- [x] `contracts/tokens/ERC20/ERC20PermitMintableStub.sol` exists
- [x] `foundry.toml` includes `ethereum_mainnet_infura` and `base_mainnet_infura`

## Completion Criteria

- [x] Tests pass:
  - `forge test --match-path "test/foundry/fork/ethereum_main/uniswapV2/**"` (skips without INFURA_KEY)
  - `forge test --match-path "test/foundry/fork/base_main/uniswapV2/**"` (skips without INFURA_KEY)
  - `forge test --match-path "test/foundry/spec/protocols/dexes/uniswap/v2/**"` (8 tests pass)
- [x] Tests skip gracefully when `INFURA_KEY` is not set

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
