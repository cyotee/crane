// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/UInt256SetRepo.sol";

// Invariant testing handler for UInt256SetRepo
contract UInt256SetRepoHandler {
    using UInt256SetRepo for UInt256Set;
    UInt256Set internal s;

    // Map arbitrary uint input to a small seed space 1..16
    function valFromSeed(uint256 seed) public pure returns (uint256) {
        return (seed % 16) + 1;
    }

    // Positive-path operations
    function add_seed(uint256 seed) external {
        s._add(valFromSeed(seed));
    }

    function add_many(uint256[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        uint256[] memory batch = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            batch[i] = valFromSeed(arr[i]);
        }
        s._add(batch);
    }

    function remove_seed(uint256 seed) external {
        s._remove(valFromSeed(seed));
    }

    function remove_many(uint256[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        for (uint256 i = 0; i < n; i++) {
            s._remove(valFromSeed(arr[i]));
        }
    }

    // View helpers
    function asArray() external view returns (uint256[] memory) {
        uint256[] storage vals = s._values();
        uint256[] memory arr = new uint256[](vals.length);
        for (uint256 i = 0; i < vals.length; i++) {
            arr[i] = vals[i];
        }
        return arr;
    }

    function indexOf(uint256 a) external view returns (uint256) {
        return s._indexOf(a);
    }

    function maxValue() external view returns (uint256) {
        return s._max();
    }
}

contract UInt256SetRepoInvariantTest is Test {
    UInt256SetRepoHandler public handler;

    function setUp() public {
        handler = new UInt256SetRepoHandler();

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
        uint256[] memory arr = handler.asArray();
        for (uint256 i = 0; i < arr.length; i++) {
            uint256 idx = handler.indexOf(arr[i]);
            assertEq(idx, i);
        }
    }

    // Invariant: indexOf for missing returns MAX
    function invariant_indexOf_missing_returns_max() public view {
        uint256 idx = handler.indexOf(type(uint256).max);
        assert(idx == type(uint256).max);
    }

    // Invariant: tracked maxValue equals highest element in array (or 0)
    function invariant_max_consistent() public view {
        uint256[] memory arr = handler.asArray();
        uint256 reported = handler.maxValue();
        uint256 actual = 0;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > actual) actual = arr[i];
        }
        assert(reported >= actual);
    }
}

