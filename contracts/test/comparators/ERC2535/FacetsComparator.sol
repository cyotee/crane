// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {AddressSetComparatorRepo, AddressSetComparator} from "@crane/contracts/test/comparators/AddressSetComparator.sol";
import {Bytes4SetComparatorRepo, Bytes4SetComparator} from "@crane/contracts/test/comparators/Bytes4SetComparator.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {SetComparatorLogger} from "@crane/contracts/test/comparators/SetComparatorLogger.sol";
import {Bytes32} from "@crane/contracts/utils/Bytes32.sol";

library FacetsComparatorRepo {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;

    function _recFacet(IDiamondLoupe subject, address facet, bytes4[] memory expected) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
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
        Bytes4SetComparatorRepo._recExpectedBytes4(
            // address subject,
            address(facet),
            // bytes4 func,
            IDiamondLoupe.facets.selector,
            // bytes4[] memory expected
            expected
        );
    }

    function _expectedFacets(IDiamondLoupe subject) internal view returns (IDiamondLoupe.Facet[] memory expected) {
        uint256 expectedAddrLen =
            AddressSetComparatorRepo._recedExpectedAddrs(address(subject), IDiamondLoupe.facets.selector)._length();
        expected = new IDiamondLoupe.Facet[](expectedAddrLen);
        for (uint256 expectedAddrCursor = 0; expectedAddrCursor < expectedAddrLen; expectedAddrCursor++) {
            expected[expectedAddrCursor] = IDiamondLoupe.Facet({
                facetAddress: AddressSetComparatorRepo._recedExpectedAddrs(
                        address(subject), IDiamondLoupe.facets.selector
                    )._index(expectedAddrCursor),
                functionSelectors: Bytes4SetComparatorRepo._recedExpectedBytes4(
                        expected[expectedAddrCursor].facetAddress, IDiamondLoupe.facets.selector
                    )._values()
            });
        }
    }
}

library FacetsComparator {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using Bytes32 for bytes32;

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
            SetComparatorLogger._logLengthMismatch(expected.length, actual.length, errorPrefix, errorSuffixFacetFuncs);
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
            AddressSetComparatorRepo._recExpectedAddrs(
                address(subject), IDiamondLoupe.facets.selector, expected[actualCursor].facetAddress
            );

            // Check function selector lengths for this facet
            if (expected[actualCursor].functionSelectors.length != actual[actualCursor].functionSelectors.length) {
                SetComparatorLogger._logLengthMismatch(
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
                Bytes4SetComparatorRepo._recExpectedBytes4(
                    expectFacetFuncsKey, IDiamondLoupe.facets.selector, expected[actualCursor].functionSelectors
                );

                bool funcsMatches = Bytes4SetComparator._compare(
                    // bytes4[] memory expected,
                    Bytes4SetComparatorRepo._recedExpectedBytes4(expectFacetFuncsKey, IDiamondLoupe.facets.selector)
                        ._values(),
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
        isValid = AddressSetComparator._compare(
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(address(subject), IDiamondLoupe.facets.selector)._values(),
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
            SetComparatorLogger._logLengthMismatch(
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
