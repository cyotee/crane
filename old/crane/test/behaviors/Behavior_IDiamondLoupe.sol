// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {Behavior} from "contracts/crane/test/behaviors/Behavior.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {BetterBytes as Bytes} from "contracts/crane/utils/BetterBytes.sol";
import {Bytes4} from "contracts/crane/utils/Bytes4.sol";
import {Bytes32} from "@crane/src/utils/Bytes32.sol";
import {BetterStrings as Strings} from "contracts/crane/utils/BetterStrings.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";
import {BetterMath as Math} from "contracts/crane/utils/math/BetterMath.sol";
import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/src/utils/collections/sets/Bytes4SetRepo.sol";
import {Bytes32Set, Bytes32SetRepo} from "@crane/src/utils/collections/sets/Bytes32SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/src/utils/collections/sets/StringSetRepo.sol";
import {UInt256Set, UInt256SetRepo} from "@crane/src/utils/collections/sets/UInt256SetRepo.sol";
import {FacetsComparator} from "contracts/crane/test/comparators/erc2535/FacetsComparator.sol";
import {IDiamondLoupe} from "contracts/crane/interfaces/IDiamondLoupe.sol";

/**
 * @title Behavior_IDiamondLoupe
 * @notice Behavior contract for testing IDiamondLoupe implementations
 * @dev Validates that contracts correctly implement the IDiamondLoupe interface
 *      by checking facet configurations, function selectors, and facet addresses
 */
contract Behavior_IDiamondLoupe is Behavior, FacetsComparator {
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

    using Math for uint256;

    /* ------------------------- State Variables ---------------------------- */
    /// forge-lint: disable-next-line(mixed-case-variable)
    mapping(IDiamondLoupe subject => mapping(bytes4 func => address facet)) private _expected_facetAddr;

    /* ------------------------- Helper Functions --------------------------- */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IDiamondLoupeName() internal pure returns (string memory) {
        return type(Behavior_IDiamondLoupe).name;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _idiamondLoupe_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        view
        virtual
        returns (string memory)
    {
        return _errPrefix(_Behavior_IDiamondLoupeName(), testedFuncSig, subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _idiamondLoupe_errPrefix(string memory testedFuncSig, address subject)
        internal
        view
        virtual
        returns (string memory)
    {
        return _errPrefix(_Behavior_IDiamondLoupeName(), testedFuncSig, subject);
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
    function expect_IDiamondLoupe(IDiamondLoupe subject, IDiamondLoupe.Facet[] memory expected) public {
        console.logBehaviorEntry(_Behavior_IDiamondLoupeName(), "expect_IDiamondLoupe");

        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            console.logBehaviorExpectation(
                _Behavior_IDiamondLoupeName(),
                "expect_IDiamondLoupe",
                "facet",
                vm.getLabel(expected[expectedCursor].facetAddress)
            );

            _recFacet(subject, expected[expectedCursor].facetAddress, expected[expectedCursor].functionSelectors);

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
    ) public returns (bool isValid) {
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
    function hasValid_IDiamondLoupe(IDiamondLoupe subject) public returns (bool isValid) {
        console.logBehaviorEntry(_Behavior_IDiamondLoupeName(), "hasValid_IDiamondLoupe");

        isValid = true;
        IDiamondLoupe.Facet[] memory actual = subject.facets();

        // Check facet configurations
        bool result = _compareFacets(
            subject,
            _expectedFacets(subject),
            actual,
            _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facets(), vm.getLabel(address(subject))),
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
            subject, _recedExpectedAddrs(address(subject), IDiamondLoupe.facetAddresses.selector)._values(), actualAddrs
        );

        if (!addressesValid) {
            isValid = false;
        }

        // Check function selectors for each facet
        for (uint256 addrsCursor = 0; addrsCursor < actualAddrs.length; addrsCursor++) {
            bytes4[] memory expectedFuncs =
                _recedExpectedBytes4(actualAddrs[addrsCursor], IDiamondLoupe.facetFunctionSelectors.selector)._values();

            result = _compare(
                expectedFuncs,
                subject.facetFunctionSelectors(actualAddrs[addrsCursor]),
                _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetFunctionSelectors(), address(subject)),
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
    function funcSig_facets() public pure returns (string memory) {
        return "facets()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facets() public pure returns (string memory) {
        return "facets";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facets_funcs(string memory facetLabel) public pure returns (string memory) {
        return string.concat("facet functions for facet ", facetLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facets_funcs(IDiamondLoupe subject) public view returns (string memory) {
        return string.concat("facets functions for facet ", vm.getLabel(address(subject)));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facets(
        IDiamondLoupe subject,
        IDiamondLoupe.Facet[] memory expected,
        IDiamondLoupe.Facet[] memory actual
    ) public returns (bool isValid) {
        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            _recFacet(subject, expected[expectedCursor].facetAddress, expected[expectedCursor].functionSelectors);
        }
        return _compareFacets(
            subject,
            expected,
            actual,
            _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facets(), vm.getLabel(address(subject))),
            errSuffix_facets(),
            errSuffix_facets_funcs(subject)
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facets(IDiamondLoupe subject, IDiamondLoupe.Facet[] memory expected) public {
        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            _recFacet(subject, expected[expectedCursor].facetAddress, expected[expectedCursor].functionSelectors);
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facets(IDiamondLoupe subject) public returns (bool isValid) {
        return _compareFacets(
            subject,
            _expectedFacets(subject),
            subject.facets(),
            _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facets(), vm.getLabel(address(subject))),
            errSuffix_facets(),
            errSuffix_facets_funcs(subject)
        );
    }

    /* ------------------- facetFunctionSelectors(address) ------------------ */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetFunctionSelectors() public pure returns (string memory) {
        return "facetFunctionSelectors(address)";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetFunctionSelectors(
        string memory subjectLabel,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) public returns (bool valid) {
        return _compare(
            expected,
            actual,
            _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetFunctionSelectors(), subjectLabel),
            errSuffix_facets_funcs(subjectLabel)
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetFunctionSelectors(
        IDiamondLoupe subject,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) public returns (bool valid) {
        // declareAddr(address(subject));
        return areValid_IDiamondLoupe_facetFunctionSelectors(vm.getLabel(address(subject)), expected, actual);
    }

    // TODO Fix to map facet functions to subject because different proxies may use different parts of a facet.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetFunctionSelectors(
        IDiamondLoupe, // subject,
        address facet,
        bytes4[] memory expectedFuncs_
    ) public {
        // declareAddr(address(subject));
        _recExpectedBytes4(address(facet), IDiamondLoupe.facetFunctionSelectors.selector, expectedFuncs_);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facetFunctionSelectors(IDiamondLoupe subject, address facet)
        public
        returns (bool isValid_)
    {
        return areValid_IDiamondLoupe_facetFunctionSelectors(
            // address subject,
            subject,
            // bytes4[] memory expected,
            _recedExpectedBytes4(facet, IDiamondLoupe.facetFunctionSelectors.selector)._values(),
            // bytes4[] memory actual
            subject.facetFunctionSelectors(facet)
        );
    }

    /* -------------------------- facetAddresses() -------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetAddresses() public pure returns (string memory) {
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
    ) public returns (bool valid) {
        return _compare(
            expected,
            actual,
            _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetAddresses(), subjectName),
            errSuffix_facetAddresses()
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetAddresses(
        IDiamondLoupe subject,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool valid) {
        // declareAddr(address(subject));
        return areValid_IDiamondLoupe_facetAddresses(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddresses(IDiamondLoupe subject, address[] memory expectedFacetAddresses_)
        public
    {
        // declareAddr(address(subject));
        _recExpectedAddrs(address(subject), IDiamondLoupe.facetAddresses.selector, expectedFacetAddresses_);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddresses(IDiamondLoupe subject, address expectedFacetAddress_) public {
        // declareAddr(address(subject));
        _recExpectedAddrs(address(subject), IDiamondLoupe.facetAddresses.selector, expectedFacetAddress_);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facetAddresses(IDiamondLoupe subject) public returns (bool isValid_) {
        return areValid_IDiamondLoupe_facetAddresses(
            // address subject,
            subject,
            // bytes4[] memory expected,
            _recedExpectedAddrs(address(subject), IDiamondLoupe.facetAddresses.selector)._values(),
            // bytes4[] memory actual
            subject.facetAddresses()
        );
    }

    /* ------------------------ facetAddress(bytes4) ------------------------ */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetAddress() public pure returns (string memory) {
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
    ) public view returns (bool isValid) {
        isValid = expected == actual;
        if (!isValid) {
            console.log(
                string.concat(
                    _errPrefix(_Behavior_IDiamondLoupeName(), funcSig_facetAddress(), subjectName),
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
                    func.toString()
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
        public
        view
        returns (bool valid)
    {
        // declareAddr(address(subject));
        return areValid_IDiamondLoupe_facetAddress(vm.getLabel(address(subject)), func, expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddress(IDiamondLoupe subject, bytes4 func, address facet) public {
        _expected_facetAddr[subject][func] = facet;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondLoupe_facetAddress(IDiamondLoupe subject, bytes4[] memory funcs, address facet) public {
        for (uint256 cursor = 0; cursor < funcs.length; cursor++) {
            _expected_facetAddr[subject][funcs[cursor]] = facet;
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondLoupe_facetAddress(IDiamondLoupe subject) public view returns (bool isValid) {
        isValid = true;
        address[] memory actualFacetAddrs = subject.facetAddresses();
        for (uint256 actualAddrCursor = 0; actualAddrCursor < actualFacetAddrs.length; actualAddrCursor++) {
            bytes4[] memory actualFacetFuncs = subject.facetFunctionSelectors(actualFacetAddrs[actualAddrCursor]);
            for (uint256 funcsCursor = 0; funcsCursor < actualFacetFuncs.length; funcsCursor++) {
                bool matches =
                    _expected_facetAddr[subject][actualFacetFuncs[funcsCursor]] == actualFacetAddrs[actualAddrCursor];
                if (!matches) {
                    isValid = false;
                    console.log(
                        string.concat(
                            _errPrefix(
                                _Behavior_IDiamondLoupeName(), funcSig_facetAddress(), vm.getLabel(address(subject))
                            ),
                            " function mapping mismatch "
                        )
                    );
                    console.logCompare(
                        // string memory subjectLabel
                        string.concat("subject: ", vm.getLabel(address(subject))),
                        // string memory logBody
                        string.concat("function: ", actualFacetFuncs[funcsCursor].toString()),
                        // string memory expectedLog
                        string.concat(
                            "expected: ", _expected_facetAddr[subject][actualFacetFuncs[funcsCursor]].toString()
                        ),
                        // string memory actualLog
                        string.concat("actual: ", actualFacetAddrs[actualAddrCursor].toString())
                    );
                }
            }
        }
    }
}
