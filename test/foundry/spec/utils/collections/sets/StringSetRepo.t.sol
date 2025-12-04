// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/StringSetRepo.sol";

// Invariant testing handler for StringSetRepo
contract StringSetRepoHandler {
    using StringSetRepo for StringSet;
    StringSet internal s;

    // Map arbitrary uint input to a small set of short strings to keep state compact
    function strFromSeed(uint256 seed) public pure returns (string memory) {
        uint256 v = (seed % 16) + 1; // 1..16
        if (v < 10) return string(abi.encodePacked("s", bytes1(uint8(48 + v))));
        // v 10..16 -> 'sa'..'sg'
        return string(abi.encodePacked("s", bytes1(uint8(87 + v))));
    }

    // Positive-path operations
    function add_seed(uint256 seed) external {
        s._add(strFromSeed(seed));
    }

    function add_many(string[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        for (uint256 i = 0; i < n; i++) {
            s._add(strFromSeed(uint256(keccak256(bytes(arr[i])))));
        }
    }

    function remove_seed(uint256 seed) external {
        s._remove(strFromSeed(seed));
    }

    function remove_many(string[] calldata arr) external {
        uint256 n = arr.length;
        if (n > 8) n = 8;
        for (uint256 i = 0; i < n; i++) {
            string memory v = strFromSeed(uint256(keccak256(bytes(arr[i]))));
            s._remove(v);
        }
    }

    // View helpers
    function asArray() external view returns (string[] memory) {
        string[] storage vals = s._values();
        string[] memory arr = new string[](vals.length);
        for (uint256 i = 0; i < vals.length; i++) {
            arr[i] = vals[i];
        }
        return arr;
    }

    function indexOf(string calldata a) external view returns (uint256) {
        return s._indexOf(a);
    }
}

contract StringSetRepoInvariantTest is Test {
    StringSetRepoHandler public handler;

    function setUp() public {
        handler = new StringSetRepoHandler();

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
        string[] memory arr = handler.asArray();
        for (uint256 i = 0; i < arr.length; i++) {
            uint256 idx = handler.indexOf(arr[i]);
            assertEq(idx, i);
        }
    }

    // Invariant: indexOf for missing returns MAX
    function invariant_indexOf_missing_returns_max() public view {
        uint256 idx = handler.indexOf("__MISSING__");
        assert(idx == type(uint256).max);
    }

    // Placeholder: no sort operation for strings in repo
    function invariant_sorted_after_sort_ops() public pure {
        return;
    }
}

