// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {Bytes4} from "@crane/contracts/utils/Bytes4.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {AddressSetComparatorRepo, AddressSetComparator} from "@crane/contracts/test/comparators/AddressSetComparator.sol";
import {Bytes4SetComparatorRepo, Bytes4SetComparator} from "@crane/contracts/test/comparators/Bytes4SetComparator.sol";
import {FacetsComparatorRepo, FacetsComparator} from "@crane/contracts/test/comparators/ERC2535/FacetsComparator.sol";

struct Behavior_IDiamondLoupeLayout {
    /// forge-lint: disable-next-line(mixed-case-variable)
    mapping(IDiamondLoupe subject => mapping(bytes4 func => address facet)) expected_facetAddr;
}

library Behavior_IDiamondLoupeRepo {
    bytes32 internal constant _BEHAVIOR_IDIAMONDLOUPE_LAYOUT_STORAGE_SLOT =
        keccak256(abi.encode(type(Behavior_IDiamondLoupeRepo).name));

    function _layout(bytes32 slot_) internal pure returns (Behavior_IDiamondLoupeLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Behavior_IDiamondLoupeLayout storage) {
        return _layout(_BEHAVIOR_IDIAMONDLOUPE_LAYOUT_STORAGE_SLOT);
    }

    function _expected_facetAddr(Behavior_IDiamondLoupeLayout storage layout, IDiamondLoupe subject, bytes4 func)
        internal
        view
        returns (address)
    {
        return layout.expected_facetAddr[subject][func];
    }

    function _expected_facetAddr(IDiamondLoupe subject, bytes4 func) internal view returns (address) {
        return _layout().expected_facetAddr[subject][func];
    }

    function _set_expected_facetAddr(
        Behavior_IDiamondLoupeLayout storage layout,
        IDiamondLoupe subject,
        bytes4 func,
        address facet
    ) internal {
        layout.expected_facetAddr[subject][func] = facet;
    }

    function _set_expected_facetAddr(IDiamondLoupe subject, bytes4 func, address facet) internal {
        _layout().expected_facetAddr[subject][func] = facet;
    }
}

library Behavior_IDiamondLoupe {
    using AddressSetRepo for AddressSet;
    using BetterAddress for address;
    using Bytes4 for bytes4;
    using Bytes4SetRepo for Bytes4Set;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    /* ------------------------- Helper Functions --------------------------- */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IDiamondLoupeName() internal pure returns (string memory) {
        return type(Behavior_IDiamondLoupe).name;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _idiamondLoupe_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), testedFuncSig, subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _idiamondLoupe_errPrefix(string memory testedFuncSig, address subject)
        internal
        view
        returns (string memory)
    {
        return BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), testedFuncSig, subject);
    }

    /* ---------------------------------------------------------------------- */
    /*                        REFAACTORED CODE IS ABOVE                       */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Sets expectations for a diamond's facet configuration
     * @param subject The diamond contract to test
     * @param expected The expected facet configuration
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe(IDiamondLoupe subject, IDiamondLoupe.Facet[] memory expected) internal {
        console.logBehaviorEntry(_Behavior_IDiamondLoupeName(), "expect_IDiamondLoupe");

        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            console.logBehaviorExpectation(
                _Behavior_IDiamondLoupeName(),
                "expect_IDiamondLoupe",
                "facet",
                vm.getLabel(expected[expectedCursor].facetAddress)
            );

            FacetsComparatorRepo._recFacet(
                subject, expected[expectedCursor].facetAddress, expected[expectedCursor].functionSelectors
            );

            expect_IDiamondLoupe_facetAddress(
                subject, expected[expectedCursor].functionSelectors, expected[expectedCursor].facetAddress
            );
        }

        console.logBehaviorExit(_Behavior_IDiamondLoupeName(), "expect_IDiamondLoupe");
    }

    /**
     * @notice Validates a diamond's facet configuration
     * @param subject The diamond contract to test
     * @param expected The expected facet configuration
     * @param actual The actual facet configuration
     * @return isValid True if the configuration matches expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe(
        IDiamondLoupe subject,
        IDiamondLoupe.Facet[] memory expected,
        IDiamondLoupe.Facet[] memory actual
    ) internal returns (bool isValid) {
        console.logBehaviorEntry(_Behavior_IDiamondLoupeName(), "areValid_IDiamondLoupe");

        isValid = areValid_IDiamondLoupe_facets(subject, expected, actual);

        console.logBehaviorValidation(
            _Behavior_IDiamondLoupeName(), "areValid_IDiamondLoupe", "facet configuration", isValid
        );

        console.logBehaviorExit(_Behavior_IDiamondLoupeName(), "areValid_IDiamondLoupe");
    }

    /**
     * @notice Validates that a diamond's current state matches expectations
     * @param subject The diamond contract to test
     * @return isValid True if all facet configurations match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe(IDiamondLoupe subject) internal returns (bool isValid) {
        console.logBehaviorEntry(_Behavior_IDiamondLoupeName(), "hasValid_IDiamondLoupe");

        isValid = true;
        IDiamondLoupe.Facet[] memory actual = subject.facets();

        // Check facet configurations
        bool result = FacetsComparator._compareFacets(
            subject,
            FacetsComparatorRepo._expectedFacets(subject),
            actual,
            BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facets(), vm.getLabel(address(subject))),
            errSuffix_facets(),
            errSuffix_facets_funcs(subject)
        );

        if (!result) {
            isValid = false;
            console.logBehaviorError(
                _Behavior_IDiamondLoupeName(),
                "hasValid_IDiamondLoupe",
                "Facet configuration mismatch",
                "Expected vs actual facets differ"
            );
        }

        // Check facet addresses
        address[] memory actualAddrs = subject.facetAddresses();
        bool addressesValid = areValid_IDiamondLoupe_facetAddresses(
            subject,
            AddressSetComparatorRepo._recedExpectedAddrs(address(subject), IDiamondLoupe.facetAddresses.selector)
                ._values(),
            actualAddrs
        );

        if (!addressesValid) {
            isValid = false;
        }

        // Check function selectors for each facet
        for (uint256 addrsCursor = 0; addrsCursor < actualAddrs.length; addrsCursor++) {
            bytes4[] memory expectedFuncs = Bytes4SetComparatorRepo._recedExpectedBytes4(
                    actualAddrs[addrsCursor], IDiamondLoupe.facetFunctionSelectors.selector
                )._values();

            result = Bytes4SetComparator._compare(
                expectedFuncs,
                subject.facetFunctionSelectors(actualAddrs[addrsCursor]),
                BehaviorUtils._errPrefix(
                    _Behavior_IDiamondLoupeName(), funcSig_facetFunctionSelectors(), address(subject)
                ),
                errSuffix_facets_funcs(vm.getLabel(address(subject)))
            );

            if (!result) {
                isValid = false;
                console.logBehaviorError(
                    _Behavior_IDiamondLoupeName(),
                    "hasValid_IDiamondLoupe",
                    "Function selector mismatch",
                    vm.getLabel(actualAddrs[addrsCursor])
                );
            }

            for (uint256 funcsCursor = 0; funcsCursor < expectedFuncs.length; funcsCursor++) {
                bool facetValid = areValid_IDiamondLoupe_facetAddress(
                    subject,
                    expectedFuncs[funcsCursor],
                    subject.facetAddress(expectedFuncs[funcsCursor]),
                    actualAddrs[addrsCursor]
                );
                if (!facetValid) {
                    isValid = false;
                }
            }
        }

        console.logBehaviorValidation(
            _Behavior_IDiamondLoupeName(), "hasValid_IDiamondLoupe", "full interface", isValid
        );

        console.logBehaviorExit(_Behavior_IDiamondLoupeName(), "hasValid_IDiamondLoupe");
    }

    /* ------------------------------ facets() ------------------------------ */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facets() internal pure returns (string memory) {
        return "facets()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facets() internal pure returns (string memory) {
        return "facets";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facets_funcs(string memory facetLabel) internal pure returns (string memory) {
        return string.concat("facet functions for facet ", facetLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facets_funcs(IDiamondLoupe subject) internal view returns (string memory) {
        return string.concat("facets functions for facet ", vm.getLabel(address(subject)));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facets(
        IDiamondLoupe subject,
        IDiamondLoupe.Facet[] memory expected,
        IDiamondLoupe.Facet[] memory actual
    ) internal returns (bool isValid) {
        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            FacetsComparatorRepo._recFacet(
                subject, expected[expectedCursor].facetAddress, expected[expectedCursor].functionSelectors
            );
        }
        return FacetsComparator._compareFacets(
            subject,
            expected,
            actual,
            BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facets(), vm.getLabel(address(subject))),
            errSuffix_facets(),
            errSuffix_facets_funcs(subject)
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facets(IDiamondLoupe subject, IDiamondLoupe.Facet[] memory expected) internal {
        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            FacetsComparatorRepo._recFacet(
                subject, expected[expectedCursor].facetAddress, expected[expectedCursor].functionSelectors
            );
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facets(IDiamondLoupe subject) internal returns (bool isValid) {
        return FacetsComparator._compareFacets(
            subject,
            FacetsComparatorRepo._expectedFacets(subject),
            subject.facets(),
            BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facets(), vm.getLabel(address(subject))),
            errSuffix_facets(),
            errSuffix_facets_funcs(subject)
        );
    }

    /* ------------------- facetFunctionSelectors(address) ------------------ */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetFunctionSelectors() internal pure returns (string memory) {
        return "facetFunctionSelectors(address)";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetFunctionSelectors(
        string memory subjectLabel,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) internal returns (bool valid) {
        return Bytes4SetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetFunctionSelectors(), subjectLabel),
            errSuffix_facets_funcs(subjectLabel)
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetFunctionSelectors(
        IDiamondLoupe subject,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) internal returns (bool valid) {
        // declareAddr(address(subject));
        return areValid_IDiamondLoupe_facetFunctionSelectors(vm.getLabel(address(subject)), expected, actual);
    }

    // TODO Fix to map facet functions to subject because different proxies may use different parts of a facet.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetFunctionSelectors(
        IDiamondLoupe, // subject,
        address facet,
        bytes4[] memory expectedFuncs_
    ) internal {
        // declareAddr(address(subject));
        Bytes4SetComparatorRepo._recExpectedBytes4(
            address(facet), IDiamondLoupe.facetFunctionSelectors.selector, expectedFuncs_
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facetFunctionSelectors(IDiamondLoupe subject, address facet)
        internal
        returns (bool isValid_)
    {
        return areValid_IDiamondLoupe_facetFunctionSelectors(
            // address subject,
            subject,
            // bytes4[] memory expected,
            Bytes4SetComparatorRepo._recedExpectedBytes4(facet, IDiamondLoupe.facetFunctionSelectors.selector)
                ._values(),
            // bytes4[] memory actual
            subject.facetFunctionSelectors(facet)
        );
    }

    /* -------------------------- facetAddresses() -------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetAddresses() internal pure returns (string memory) {
        return "facetAddresses()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facetAddresses() internal pure returns (string memory) {
        return "facet addresses";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetAddresses(
        string memory subjectName,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetAddresses(), subjectName),
            errSuffix_facetAddresses()
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetAddresses(
        IDiamondLoupe subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        // declareAddr(address(subject));
        return areValid_IDiamondLoupe_facetAddresses(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddresses(IDiamondLoupe subject, address[] memory expectedFacetAddresses_)
        internal
    {
        // declareAddr(address(subject));
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), IDiamondLoupe.facetAddresses.selector, expectedFacetAddresses_
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddresses(IDiamondLoupe subject, address expectedFacetAddress_) internal {
        // declareAddr(address(subject));
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), IDiamondLoupe.facetAddresses.selector, expectedFacetAddress_
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facetAddresses(IDiamondLoupe subject) internal returns (bool isValid_) {
        return areValid_IDiamondLoupe_facetAddresses(
            // address subject,
            subject,
            // bytes4[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(address(subject), IDiamondLoupe.facetAddresses.selector)
                ._values(),
            // bytes4[] memory actual
            subject.facetAddresses()
        );
    }

    /* ------------------------ facetAddress(bytes4) ------------------------ */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetAddress() internal pure returns (string memory) {
        return "facetAddress(bytes4)";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facetAddress() internal pure returns (string memory) {
        return "facet of function";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetAddress(
        string memory subjectName,
        bytes4 func,
        address expected,
        address actual
    ) internal view returns (bool isValid) {
        isValid = expected == actual;
        if (!isValid) {
            console.log(
                string.concat(
                    BehaviorUtils._errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetAddress(), subjectName),
                    " declares the incorrect facet for that function. "
                )
            );
            console.logCompare(
                // string memory subjectLabel
                subjectName,
                // string memory logBody
                string.concat(
                    "func: ",
                    // TODO makes bytes 4 length specific version with trimming from String library.
                    func._toString()
                ),
                // string memory expectedLog
                vm.getLabel(address(expected)),
                // string memory actualLog
                vm.getLabel(address(actual))
            );
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetAddress(IDiamondLoupe subject, bytes4 func, address expected, address actual)
        internal
        view
        returns (bool valid)
    {
        // declareAddr(address(subject));
        return areValid_IDiamondLoupe_facetAddress(vm.getLabel(address(subject)), func, expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddress(IDiamondLoupe subject, bytes4 func, address facet) internal {
        Behavior_IDiamondLoupeRepo._set_expected_facetAddr(subject, func, facet);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddress(IDiamondLoupe subject, bytes4[] memory funcs, address facet) internal {
        for (uint256 cursor = 0; cursor < funcs.length; cursor++) {
            // _expected_facetAddr[subject][funcs[cursor]] = facet;
            Behavior_IDiamondLoupeRepo._set_expected_facetAddr(subject, funcs[cursor], facet);
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facetAddress(IDiamondLoupe subject) internal view returns (bool isValid) {
        isValid = true;
        address[] memory actualFacetAddrs = subject.facetAddresses();
        for (uint256 actualAddrCursor = 0; actualAddrCursor < actualFacetAddrs.length; actualAddrCursor++) {
            bytes4[] memory actualFacetFuncs = subject.facetFunctionSelectors(actualFacetAddrs[actualAddrCursor]);
            for (uint256 funcsCursor = 0; funcsCursor < actualFacetFuncs.length; funcsCursor++) {
                bool matches =
                // _expected_facetAddr[subject][actualFacetFuncs[funcsCursor]] == actualFacetAddrs[actualAddrCursor];
                 Behavior_IDiamondLoupeRepo._expected_facetAddr(subject, actualFacetFuncs[funcsCursor])
                    == actualFacetAddrs[actualAddrCursor];
                if (!matches) {
                    isValid = false;
                    console.log(
                        string.concat(
                            BehaviorUtils._errPrefix(
                                _Behavior_IDiamondLoupeName(), funcSig_facetAddress(), vm.getLabel(address(subject))
                            ),
                            " function mapping mismatch "
                        )
                    );
                    console.logCompare(
                        // string memory subjectLabel
                        string.concat("subject: ", vm.getLabel(address(subject))),
                        // string memory logBody
                        string.concat("function: ", actualFacetFuncs[funcsCursor]._toString()),
                        // string memory expectedLog
                        string.concat(
                            "expected: ",
                            // _expected_facetAddr[subject][actualFacetFuncs[funcsCursor]].toString()
                            Behavior_IDiamondLoupeRepo._expected_facetAddr(subject, actualFacetFuncs[funcsCursor])
                                ._toString()
                        ),
                        // string memory actualLog
                        string.concat("actual: ", actualFacetAddrs[actualAddrCursor]._toString())
                    );
                }
            }
        }
    }
}
