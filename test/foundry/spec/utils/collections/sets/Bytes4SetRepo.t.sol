// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/Bytes4SetRepo.sol";

// Invariant testing handler for Bytes4SetRepo
contract Bytes4SetRepoHandler {
    using Bytes4SetRepo for Bytes4Set;
    Bytes4Set internal s;

    // Map arbitrary uint input to a small set of bytes4 values to keep state compact
    function valFromSeed(uint256 seed) public pure returns (bytes4) {
        return bytes4(uint32((seed % 16) + 1)); // values 1..16
    }

    // Positive-path operations
    function add_seed(uint256 seed) external {
        s._add(valFromSeed(seed));
        _lastWasSort = false;
    }

    function add_many(bytes4[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        bytes4[] memory toAdd = new bytes4[](n);
        for (uint256 i = 0; i < n; i++) {
            toAdd[i] = valFromSeed(uint256(uint32(uint32(arr[i]))));
            s._add(toAdd[i]);
        }
        _lastWasSort = false;
    }

    function remove_seed(uint256 seed) external {
        s._remove(valFromSeed(seed));
        _lastWasSort = false;
    }

    function remove_many(bytes4[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        bytes4[] memory toRemove = new bytes4[](n);
        for (uint256 i = 0; i < n; i++) {
            toRemove[i] = valFromSeed(uint256(uint32(uint32(arr[i]))));
        }
        s._remove(toRemove);
        _lastWasSort = false;
    }

    // small parity flag (not used)
    bool internal _lastWasSort;

    // View helpers
    function asArray() external view returns (bytes4[] memory) {
        return s._asArray();
    }

    function indexOf(bytes4 a) external view returns (uint256) {
        return s._indexOf(a);
    }

    function lastWasSort() external view returns (bool) {
        return _lastWasSort;
    }
}

contract Bytes4SetRepoInvariantTest is Test {
    Bytes4SetRepoHandler public handler;

    function setUp() public {
        handler = new Bytes4SetRepoHandler();

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
        bytes4[] memory arr = handler.asArray();
        for (uint256 i = 0; i < arr.length; i++) {
            uint256 idx = handler.indexOf(arr[i]);
            assertEq(idx, i);
        }
    }

    // Invariant: indexOf for missing returns MAX
    function invariant_indexOf_missing_returns_max() public view {
        bytes4 missing = bytes4(uint32(0xFFFF));
        uint256 idx = handler.indexOf(missing);
        assert(idx == type(uint256).max);
    }

    // No sorting in this repo; placeholder invariant
    function invariant_sorted_after_sort_ops() public pure {
        return;
    }
}

