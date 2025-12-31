// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {BetterBytes as Bytes} from "contracts/crane/utils/BetterBytes.sol";
import {Bytes4} from "contracts/crane/utils/Bytes4.sol";
import {Bytes32} from "@crane/src/utils/Bytes32.sol";
import {BetterStrings as Strings} from "contracts/crane/utils/BetterStrings.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";
import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/src/utils/collections/sets/Bytes4SetRepo.sol";
import {Bytes32Set, Bytes32SetRepo} from "@crane/src/utils/collections/sets/Bytes32SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/src/utils/collections/sets/StringSetRepo.sol";
import {UInt256Set, UInt256SetRepo} from "@crane/src/utils/collections/sets/UInt256SetRepo.sol";

import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";

import {
    AddressSetComparatorStorage,
    AddressSetComparator
} from "contracts/crane/test/comparators/sets/AddressSetComparator.sol";
import {
    Bytes4SetComparatorStorage,
    Bytes4SetComparator
} from "contracts/crane/test/comparators/sets/Bytes4SetComparator.sol";

import {IDiamondLoupe} from "contracts/crane/interfaces/IDiamondLoupe.sol";

contract FacetsComparatorStorage is AddressSetComparatorStorage, Bytes4SetComparatorStorage {
    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using Bytes32SetRepo for Bytes32Set;
    using StringSetRepo for StringSet;
    using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    function _recFacet(IDiamondLoupe subject, address facet, bytes4[] memory expected) internal {
        _recExpectedAddrs(
            // address subject,
            address(subject),
            // bytes4 func,
            IDiamondLoupe.facets.selector,
            // address expected
            facet
        );
        _recFacetFuncs(
            // address facet,
            facet,
            // bytes[] memory expected
            expected
        );
    }

    function _recFacetFuncs(address facet, bytes4[] memory expected) internal {
        _recExpectedBytes4(
            // address subject,
            address(facet),
            // bytes4 func,
            IDiamondLoupe.facets.selector,
            // bytes4[] memory expected
            expected
        );
    }

    function _expectedFacets(IDiamondLoupe subject) internal view returns (IDiamondLoupe.Facet[] memory expected) {
        uint256 expectedAddrLen = _recedExpectedAddrs(address(subject), IDiamondLoupe.facets.selector).
            // address subject,
            // bytes4 func
            _length();
        expected = new IDiamondLoupe.Facet[](expectedAddrLen);
        for (uint256 expectedAddrCursor = 0; expectedAddrCursor < expectedAddrLen; expectedAddrCursor++) {
            expected[expectedAddrCursor] = IDiamondLoupe.Facet({
                facetAddress: _recedExpectedAddrs(address(subject), IDiamondLoupe.facets.selector).
                    // address subject,
                    // bytes4 func
                    _index(expectedAddrCursor),
                functionSelectors: _recedExpectedBytes4(
                        expected[expectedAddrCursor].facetAddress, IDiamondLoupe.facets.selector
                    ).
                    // address subject,
                    // bytes4 func
                    _values()
            });
        }
    }
}

contract FacetsComparator is AddressSetComparator, Bytes4SetComparator, FacetsComparatorStorage {
    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using Bytes32SetRepo for Bytes32Set;
    using StringSetRepo for StringSet;
    using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    function _procFacets(
        IDiamondLoupe subject,
        IDiamondLoupe.Facet[] memory expected,
        IDiamondLoupe.Facet[] memory actual,
        string memory errorPrefix,
        string memory errorSuffixFacetFuncs
    ) internal returns (bool isValid, address[] memory actualFacetAddrs) {
        // console.log("FacetsComparator:_procFacets:: Entering function.");
        isValid = true;
        actualFacetAddrs = new address[](actual.length);

        // First check array lengths match
        if (expected.length != actual.length) {
            _logLengthMismatch(expected.length, actual.length, errorPrefix, errorSuffixFacetFuncs);
            isValid = false;
            // Still populate actualFacetAddrs with what we have for address comparison
            for (uint256 i = 0; i < actual.length; i++) {
                actualFacetAddrs[i] = actual[i].facetAddress;
            }
            // Short-circuit if facet lengths mismiatch.
            return (isValid, actualFacetAddrs);
        }

        for (uint256 actualCursor = 0; actualCursor < actual.length; actualCursor++) {
            // console.log("Processing facet ", actualCursor);
            actualFacetAddrs[actualCursor] = actual[actualCursor].facetAddress;

            // Store facet address in subject's storage for this facet
            _recExpectedAddrs(address(subject), IDiamondLoupe.facets.selector, expected[actualCursor].facetAddress);

            // Check function selector lengths for this facet
            if (expected[actualCursor].functionSelectors.length != actual[actualCursor].functionSelectors.length) {
                _logLengthMismatch(
                    expected[actualCursor].functionSelectors.length,
                    actual[actualCursor].functionSelectors.length,
                    errorPrefix,
                    errorSuffixFacetFuncs
                );
                isValid = false;
                // Short-circuit function selector comparison for this facet
                // continue;
            } else {
                // Only store and compare function selectors if lengths match
                address expectFacetFuncsKey =
                    keccak256(abi.encode(subject, actual[actualCursor].facetAddress))._toAddress();
                _recExpectedBytes4(
                    expectFacetFuncsKey, IDiamondLoupe.facets.selector, expected[actualCursor].functionSelectors
                );

                bool funcsMatches = _compare(
                    // bytes4[] memory expected,
                    _recedExpectedBytes4(expectFacetFuncsKey, IDiamondLoupe.facets.selector).
                        // address subject,
                        // bytes4 func
                        _values(),
                    // bytes4[] memory actual,
                    actual[actualCursor].functionSelectors,
                    // string memory errorPrefix,
                    errorPrefix,
                    // string memory errorSuffix
                    errorSuffixFacetFuncs
                );
                if (funcsMatches == false) {
                    isValid = false;
                }
            }
        }
        // console.log("FacetsComparator:_procFacets:: Exiting function.");
        return (isValid, actualFacetAddrs);
    }

    function _procFacetAddrs(
        IDiamondLoupe subject,
        address[] memory actualFacetAddrs,
        string memory errorPrefix,
        string memory errorSuffixFacets
    ) internal returns (bool isValid) {
        isValid = _compare(
            // address[] memory expected,
            _recedExpectedAddrs(address(subject), IDiamondLoupe.facets.selector).
                // address subject,
                // bytes4 func
                _values(),
            // address[] memory actual,
            actualFacetAddrs,
            // string memory errorPrefix,
            // funcSig_facets(),
            errorPrefix,
            // string memory errorSuffix
            // errSuffix_facets()
            errorSuffixFacets
        );
    }

    function _compareFacets(
        IDiamondLoupe subject,
        IDiamondLoupe.Facet[] memory expected,
        IDiamondLoupe.Facet[] memory actual,
        string memory errorPrefix,
        string memory errorSuffixFacets,
        string memory errorSuffixFacetFuncs
    ) internal returns (bool isValid) {
        // console.log("FacetsComparator:_compareFacets:: Entering function.");
        if (expected.length != actual.length) {
            _logLengthMismatch(
                // uint256 expectedLen,
                expected.length,
                // uint256 actualLen,
                actual.length,
                // string memory errorPrefix,
                errorPrefix,
                // string memory errorSuffix
                errorSuffixFacets
            );
        }
        address[] memory actualFacetAddrs;
        // console.log("Processing facets.");
        (isValid, actualFacetAddrs) = _procFacets(subject, expected, actual, errorPrefix, errorSuffixFacetFuncs);
        bool facetAddrsResult = _procFacetAddrs(subject, actualFacetAddrs, errorPrefix, errorSuffixFacets);
        if (isValid) {
            isValid = facetAddrsResult;
        }
        // console.log("FacetsComparator:_compareFacets:: Exiting function.");
        return isValid;
    }
}
