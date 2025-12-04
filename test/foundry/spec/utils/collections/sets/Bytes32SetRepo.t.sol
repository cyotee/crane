// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/Bytes32SetRepo.sol";

// Invariant testing handler for Bytes32SetRepo
contract Bytes32SetRepoHandler {
    using Bytes32SetRepo for Bytes32Set;
    Bytes32Set internal s;

    // Map arbitrary uint input to a small set of bytes32 values to keep state compact
    function valFromSeed(uint256 seed) public pure returns (bytes32) {
        return bytes32(uint256((seed % 16) + 1)); // values 1..16
    }

    // Positive-path operations
    function add_seed(uint256 seed) external {
        s._add(valFromSeed(seed));
        _lastWasSort = false;
    }

    function add_many(bytes32[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8; // bound size to small to avoid huge arrays
        for (uint256 i = 0; i < n; i++) {
            s._add(valFromSeed(uint256(arr[i])));
        }
        _lastWasSort = false;
    }

    function remove_seed(uint256 seed) external {
        s._remove(valFromSeed(seed));
        _lastWasSort = false;
    }

    function remove_many(bytes32[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        bytes32[] memory toRemove = new bytes32[](n);
        for (uint256 i = 0; i < n; i++) {
            toRemove[i] = valFromSeed(uint256(arr[i]));
        }
        s._remove(toRemove);
        _lastWasSort = false;
    }

    // track if last mutating operation was a sort (not used for this repo but kept for parity)
    bool internal _lastWasSort;

    // View helpers
    function indexOf(bytes32 a) external view returns (uint256) {
        return s._indexOf(a);
    }

    // Provide a memory copy of underlying storage values
    function asArray() external view returns (bytes32[] memory) {
        bytes32[] storage vals = s._values();
        bytes32[] memory arr = new bytes32[](vals.length);
        for (uint256 i = 0; i < vals.length; i++) {
            arr[i] = vals[i];
        }
        return arr;
    }

    function lastWasSort() external view returns (bool) {
        return _lastWasSort;
    }
}

contract Bytes32SetRepoInvariantTest is Test {
    Bytes32SetRepoHandler public handler;

    function setUp() public {
        handler = new Bytes32SetRepoHandler();

        // Register handler for fuzzing; explicitly list selectors to keep runs focused
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.add_seed.selector;
        selectors[1] = handler.remove_seed.selector;
        selectors[2] = handler.add_many.selector;
        selectors[3] = handler.remove_many.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    // Invariant: indexes mapping is consistent with values array
    function invariant_indexes_consistent() public view {
        bytes32[] memory arr = handler.asArray();
        for (uint256 i = 0; i < arr.length; i++) {
            uint256 idx = handler.indexOf(arr[i]);
            assertEq(idx, i);
        }
    }

    // Invariant: indexOf for missing returns MAX
    function invariant_indexOf_missing_returns_max() public view {
        bytes32 missing = bytes32(uint256(0xFFFF));
        uint256 idx = handler.indexOf(missing);
        assert(idx == type(uint256).max);
    }

    // Invariant: values are sorted after sort/quickSort operations
    function invariant_sorted_after_sort_ops() public pure {
        // No-op for Bytes32SetRepo: sorting operations are not supported.
        // Keep invariant placeholder for parity with other set tests.
        return;
    }
}

