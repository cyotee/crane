// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../libs/NumericArrayLib.sol";

contract SampleNumericArrayLib {
    uint256[] cachedArray;
    uint256 public cachedMedian;

    function sortTx(uint256[] memory arr) public {
        NumericArrayLib.sort(arr);
        cachedArray = arr;
    }

    // Can be used to compare gas costs with the `sortTx` function
    function updateArrayInStorage(uint256[] memory arr) public {
        cachedArray = arr;
    }

    function getCachedArray() public view returns (uint256[] memory) {
        return cachedArray;
    }

    function medianSelection(uint256[] memory arr) public {
        cachedMedian = NumericArrayLib.pickMedian(arr);
    }
}
