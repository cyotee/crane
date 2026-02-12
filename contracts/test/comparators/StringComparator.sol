// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

struct StringComparatorLayout {
    mapping(bytes4 relatedFunction => string expectedValue) expectedValues;
    mapping(bytes4 relatedFunction => string actualValue) actualValues;
}

library StringComparatorRepo {
    using BetterAddress for address;
    // using BetterEfficientHashLib for bytes;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode(type(StringComparatorRepo).name));

    function _layout(bytes32 slot) internal pure returns (StringComparatorLayout storage layout) {
        assembly {
            layout.slot := slot
        }
    }

    function _stringCompare(address subject) internal pure returns (StringComparatorLayout storage) {
        return _layout(subject._toBytes32() ^ STORAGE_SLOT);
    }

    function _recExpectedString(address subject, bytes4 func, string memory expected) internal {
        _stringCompare(subject).expectedValues[func] = expected;
    }

    function _recedExpectedString(address subject, bytes4 func) internal view returns (string memory) {
        return _stringCompare(subject).expectedValues[func];
    }

    function _recActualString(address subject, bytes4 func, string memory actual) internal {
        _stringCompare(subject).actualValues[func] = actual;
    }

    function _recedActualString(address subject, bytes4 func) internal view returns (string memory) {
        return _stringCompare(subject).actualValues[func];
    }
}

library StringComparator {
    function _compareStrings(
        string memory expected,
        string memory actual,
        string memory errorPrefix,
        string memory errorSuffix
    ) internal pure returns (bool matched) {
        matched = keccak256(abi.encodePacked(expected)) == keccak256(abi.encodePacked(actual));
        if (!matched) {
            console.logString(
                string.concat(errorPrefix, ":: Expected '", expected, "' but got '", actual, "' ", errorSuffix)
            );
        }
    }
}
