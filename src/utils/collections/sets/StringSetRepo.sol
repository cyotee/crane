// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

struct StringSet {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(string => uint256) indexes;
    string[] values;
}

library StringSetRepo {
    function _index(StringSet storage set, uint256 index) internal view returns (string memory) {
        require(set.values.length > index, "LayoutSet: index out of bounds");
        return set.values[index];
    }

    function _contains(StringSet storage set, string memory value) internal view returns (bool) {
        return set.indexes[value] != 0;
    }

    function _indexOf(StringSet storage set, string memory value) internal view returns (uint256) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }

    function _length(StringSet storage set) internal view returns (uint256) {
        return set.values.length;
    }

    // TODO Write unit tests for failure path.
    function _add(StringSet storage set, string memory value) internal returns (bool success) {
        if (!_contains(set, value)) {
            // console.log("Storing string %s", value);
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
        success = true;
    }

    function _addExclusive(StringSet storage set, string memory value) internal returns (bool success) {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
            return true;
        }
        return false;
    }

    function _add(StringSet storage set, string[] memory values) internal returns (bool allAdded) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
        allAdded = true;
    }

    function _addExclusive(StringSet storage set, string[] memory values) internal returns (bool success) {
        // for(uint256 iteration = 0; iteration < values.length; iteration++) {
        //   _add(set, values[iteration]);
        // }
        // success = true;
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            success = _addExclusive(set, values[iteration]);
            require(success == true, "StringSet: value already present.");
        }
    }

    function _remove(StringSet storage set, string memory value) internal returns (bool) {
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            string memory last = set.values[set.values.length - 1];

            // move last value to now-vacant index

            set.values[index] = last;
            set.indexes[last] = index + 1;

            // clear last index

            set.values.pop();
            delete set.indexes[value];
        }

        return true;
    }

    function _values(StringSet storage set) internal view returns (string[] storage rawSet) {
        rawSet = set.values;
        // for(uint256 iteration = 0; iteration < rawSet.length; iteration++) {
        //   console.log("Loaded string %s", rawSet[iteration]);
        // }
    }
}
