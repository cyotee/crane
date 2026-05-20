---
name: crane-chainlink-vrf
description: This skill should be used when the user asks to "integrate Chainlink VRF in Crane", "build a VRF facet", "request randomness from a Diamond", "add VRFCoordinator to a Crane repo", "fulfillRandomWords in facet", "Chainlink VRF subscription in Crane", or needs implementation guidance for Chainlink VRF v2.5 using Crane's Facet-Target-Repo and CREATE3 deployment patterns.
license: MIT
---

# Crane Chainlink VRF Integration

Use this skill when implementing VRF inside Crane's Diamond architecture. The key objective is to preserve Crane conventions (Repo storage, Facet metadata, CREATE3 deployment, TestBase patterns) while safely handling asynchronous randomness callbacks.

## Recommended Architecture in Crane

Implement VRF as a standard Facet-Target-Repo slice:

- `VRFConsumerRepo.sol` for storage and guards
- `VRFConsumerTarget.sol` for request and fulfillment logic
- `VRFConsumerFacet.sol` implementing `IFacet` metadata
- Optional package: `VRFConsumerDFPkg.sol` if you need reusable deployment bundles

### Why not rely only on base consumer inheritance?

In Diamond systems, coordinator config is typically network-specific and should be state-driven. Storing coordinator and request config in Repo state is safer and more flexible than hardcoding constructor-only assumptions.

## Storage Pattern (Repo)

Use a dedicated storage slot and explicit request tracking:

```solidity
library VRFConsumerRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("crane.protocols.oracles.chainlink.vrf.consumer");

    struct RequestStatus {
        bool exists;
        bool fulfilled;
        address requester;
        uint256[] randomWords;
        bytes payload;
    }

    struct Storage {
        address coordinator;
        bytes32 keyHash;
        uint256 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
        uint32 numWords;
        mapping(uint256 => RequestStatus) requests;
    }

    function _layoutStruct() internal pure returns (Storage storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly { l.slot := slot }
    }

    function _onlyCoordinator() internal view {
        if (msg.sender != _layoutStruct().coordinator) revert("NotVRFCoordinator");
    }
}
```

## Target Pattern

Request function:

- Builds VRF v2.5 request parameters.
- Calls coordinator `requestRandomWords(...)`.
- Persists `requestId -> RequestStatus` before returning.

Fulfillment entry point:

- Must enforce coordinator-only caller.
- Marks request fulfilled and stores random words.
- Emits deterministic events for indexing.

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
    VRFConsumerRepo._onlyCoordinator();
    // load status, validate exists + !fulfilled
    // persist words and mark fulfilled
}
```

## Facet Metadata

Expose selectors in `facetFuncs()` and interface IDs in `facetInterfaces()` like any other Crane facet. Keep callback selectors explicitly included when externally callable through the proxy.

## Deployment Pattern (Critical)

Do not deploy with `new` in scripts or production deployment flows.

Use CREATE3 factory helpers:

1. Deploy facet via `create3Factory.deployFacet(...)`
2. Deploy DFPkg via `create3Factory.deployPackageWithArgs(...)` when packaging
3. Deploy proxy instances via `diamondFactory.deploy(...)`

Use `vm.label(...)` for all deployed pieces in scripts/tests.

## Configuration Guidance

Per-network, configure at minimum:

- Coordinator address
- Key hash / gas lane
- Subscription ID (or direct-funding mode parameters)
- Callback gas limit
- Request confirmations
- Number of words

Keep these values mutable via owner/operator-governed setter functions guarded by Repo guard checks.

## Testing Strategy in Crane

### Unit + behavior tests

- Request stores status and emits event
- Fulfillment only callable by coordinator
- Duplicate fulfillment prevented
- Unknown request ID handling
- Callback gas-sensitive paths are bounded

### Integration tests

- Prefer local coordinator mocks when available in your pinned Chainlink package
- If mocks are unavailable in current dependencies, run fork tests against a real coordinator on a supported testnet configuration

Run focused tests with:

```bash
forge test --match-path test/foundry/spec/protocols/oracles/...
forge test --match-test test_VRF_*
forge test -vvv --match-test test_VRF_Fulfillment*
```

## Dependency and Remapping Notes

Crane currently tracks Chainlink interfaces under:

- `contracts/protocols/oracles/chainlink/` (price feed interfaces)

If your VRF integration requires additional Chainlink contracts (coordinator interfaces, mock coordinators, helpers), add the dependency intentionally and keep `foundry.toml` and `remappings.txt` aligned with repository conventions.

## Common Pitfalls

- Treating fulfillment as synchronous with user-triggered request transaction
- Missing request status mapping and replay prevention checks
- Hardcoding chain-specific config without upgrade path
- Forgetting to include callback selector in facet cuts
- Unbounded fulfillment loops that exceed callback gas

## Suggested File Layout

```text
contracts/protocols/oracles/chainlink/vrf/v2_5/
  VRFConsumerRepo.sol
  VRFConsumerTarget.sol
  VRFConsumerFacet.sol
  VRFConsumerFactoryService.sol        # optional
  test/bases/TestBase_VRFConsumer.sol  # optional

test/foundry/spec/protocols/oracles/chainlink/vrf/v2_5/
  VRFConsumerFacet.t.sol
  VRFConsumerIntegration.t.sol
```

## See Also

- `skill:chainlink-vrf-architecture` - VRF concepts, threat model, and method selection
- `skill:crane-architecture` - Facet/Target/Repo implementation details
- `skill:crane-access` - owner/operator guards for mutable config
- `skill:crane-deployment` - CREATE3 deployment and package wiring
- `skill:crane-testing` - behavior and testbase patterns
