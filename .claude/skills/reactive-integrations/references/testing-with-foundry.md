# Testing Reactive Contracts with Foundry

Source: https://dev.reactive.network/legacy/testing  
Lib: https://github.com/Reactive-Network/reactive-test-lib

## Install

```bash
forge install Reactive-Network/reactive-test-lib
```

```text
# remappings.txt
reactive-test-lib/=lib/reactive-test-lib/src/
```

Requirements (docs): Solidity ≥ 0.8.20, Foundry with `vm.recordLogs()`, reactive-lib v0.2.0+.

## What is mocked

| Production | Mock | Role |
|------------|------|------|
| System contract | `MockSystemContract` | Subscriptions + wildcards |
| ReactVM | `ReactiveSimulator` | Delivers logs to `react()` |
| Callback proxy | `MockCallbackProxy` | Executes callbacks + RVM ID injection |

All runs on **one** local EVM; chain IDs are logical.

`super.setUp()`:

1. Deploys mock system to `SERVICE_ADDR` = `0x0000…fffFfF`
2. Deploys `MockCallbackProxy`
3. Sets `rvmId = address(this)`
4. Sets `reactiveChainId = REACTIVE_CHAIN_ID` (`0x512512` in docs)

## One-cycle test

```solidity
import "reactive-test-lib/base/ReactiveTest.sol";

contract BasicDemoTest is ReactiveTest {
    function setUp() public override {
        super.setUp();
        // deploy origin, callback(proxy), reactive(sys, chains, origin, topic0, cb)
    }

    function testCallbackAboveThreshold() public {
        CallbackResult[] memory results = triggerAndReactWithValue(
            address(origin),
            "",
            0.01 ether,
            11155111
        );
        assertCallbackCount(results, 1);
        assertCallbackSuccess(results, 0);
    }
}
```

## Multi-step

`triggerFullCycle` / `triggerFullCycleWithValue(..., maxIterations)` loops emit → react → callback → new events until idle or max iterations (bridges).

## Cron

```solidity
triggerCron(CronType.Cron1);
advanceAndTriggerCron(100, CronType.Cron1);
```

## vmOnly contracts

After deploy: `enableVmMode(address(rc));` or `react` reverts `"VM only"`.

## Assertions

- `assertCallbackCount`, `assertNoCallbacks`
- `assertCallbackEmitted(results, target)`
- `assertCallbackSuccess` / `assertCallbackFailure`

`CallbackResult`: `chainId`, `target`, `gasLimit`, `payload` (RVM ID already injected), `success`, `returnData`.

## Routing

- `chain_id != reactiveChainId` → MockCallbackProxy  
- `chain_id == reactiveChainId` → `vm.prank(SERVICE_ADDR)` self-callback path  

## Wildcard matching

Same as production: chain `0`, contract `address(0)`, topics `REACTIVE_IGNORE`.
