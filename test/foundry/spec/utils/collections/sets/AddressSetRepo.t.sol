// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/AddressSetRepo.sol";

// Invariant testing handler for AddressSetRepo
contract AddressSetRepoHandler {
    using AddressSetRepo for AddressSet;
    AddressSet internal s;

    // Map arbitrary uint input to a small set of addresses to keep state compact
    function addrFromSeed(uint256 seed) public pure returns (address) {
        uint160 v = uint160((seed % 16) + 1); // addresses 1..16
        return address(v);
    }

    // Positive-path operations
    function add_seed(uint256 seed) external {
        s._add(addrFromSeed(seed));
        _lastWasSort = false;
    }

    function add_many(address[] calldata arr) external {
        uint256 n = arr.length;
        // bound size to small to avoid huge arrays
        if (n > 8) n = 8;
        for (uint256 i = 0; i < n; i++) {
            // map arbitrary addresses into the small seed set to keep state compact
            s._add(addrFromSeed(uint256(uint160(arr[i]))));
        }
        _lastWasSort = false;
    }

    function remove_seed(uint256 seed) external {
        s._remove(addrFromSeed(seed));
        _lastWasSort = false;
    }

    function addAsc_seed(uint256 seed) external {
        s._addAsc(addrFromSeed(seed));
        _lastWasSort = false;
    }

    function removeAsc_seed(uint256 seed) external {
        s._removeAsc(addrFromSeed(seed));
        _lastWasSort = false;
    }

    function sort() external {
        s._sortAsc();
        _lastWasSort = true;
    }

    function quickSort() external {
        s._quickSort();
        _lastWasSort = true;
    }

    // track if last mutating operation was a sort (so we only assert sortedness then)
    bool internal _lastWasSort;

    // View helpers
    function asArray() external view returns (address[] memory) {
        return s._asArray();
    }

    function indexOf(address a) external view returns (uint256) {
        return s._indexOf(a);
    }

    function range(uint256 start, uint256 end) external view returns (address[] memory) {
        return s._range(start, end);
    }

    function lastWasSort() external view returns (bool) {
        return _lastWasSort;
    }
}

contract AddressSetRepoInvariantTest is Test {
    AddressSetRepoHandler public handler;

    function setUp() public {
        handler = new AddressSetRepoHandler();

        // Register handler for fuzzing; explicitly list selectors to keep runs focused
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](8);
        selectors[0] = handler.add_seed.selector;
        selectors[1] = handler.remove_seed.selector;
        selectors[2] = handler.addAsc_seed.selector;
        selectors[3] = handler.removeAsc_seed.selector;
        selectors[4] = handler.sort.selector;
        selectors[5] = handler.quickSort.selector;
        selectors[6] = handler.add_many.selector;
        selectors[7] = handler.range.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    // Invariant: indexes mapping is consistent with values array
    function invariant_indexes_consistent() public view {
        address[] memory arr = handler.asArray();
        for (uint256 i = 0; i < arr.length; i++) {
            // AddressSetRepo stores indexes 1-based; _indexOf returns 0-based index
            uint256 idx = handler.indexOf(arr[i]);
            assertEq(idx, i);
        }
    }

    // Invariant: indexOf for missing returns MAX
    function invariant_indexOf_missing_returns_max() public view {
        address missing = address(uint160(0xFFFF));
        uint256 idx = handler.indexOf(missing);
        assert(idx == type(uint256).max);
    }

    // Invariant: values are sorted after sort/quickSort operations
    function invariant_sorted_after_sort_ops() public view {
        // Only assert sortedness if the handler indicates the last mutating op was a sort
        // (handler._lastWasSort is internal; we expose its effect by checking that
        // calling asArray() after a sort should produce a non-decreasing array.
        // The handler tracks `_lastWasSort` and sets it on sort/quickSort.)
        address[] memory arr = handler.asArray();
        if (!handler.lastWasSort()) return;
        for (uint256 i = 1; i < arr.length; i++) {
            assert(arr[i - 1] <= arr[i]);
        }
    }
}
