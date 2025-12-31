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
import {IERC8109Introspection} from "@crane/contracts/introspection/ERC8109/IERC8109Introspection.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {Bytes4} from "@crane/contracts/utils/Bytes4.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";

/* -------------------------------------------------------------------------- */
/*                          Behavior Storage Layout                           */
/* -------------------------------------------------------------------------- */

struct Behavior_IERC8109IntrospectionLayout {
    /// @dev Maps subject => function selector => expected facet address
    mapping(IERC8109Introspection subject => mapping(bytes4 selector => address facet)) expected_facetAddress;
    /// @dev Maps subject => set of expected function selectors
    mapping(IERC8109Introspection subject => Bytes4Set) expected_selectors;
}

/* -------------------------------------------------------------------------- */
/*                           Behavior Storage Repo                            */
/* -------------------------------------------------------------------------- */

library Behavior_IERC8109IntrospectionRepo {
    using Bytes4SetRepo for Bytes4Set;

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode(type(Behavior_IERC8109IntrospectionRepo).name));

    function _layout(bytes32 slot_) internal pure returns (Behavior_IERC8109IntrospectionLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Behavior_IERC8109IntrospectionLayout storage) {
        return _layout(STORAGE_SLOT);
    }

    /* ------ Expected facetAddress ------ */

    function _expected_facetAddress(
        Behavior_IERC8109IntrospectionLayout storage layout,
        IERC8109Introspection subject,
        bytes4 selector
    ) internal view returns (address) {
        return layout.expected_facetAddress[subject][selector];
    }

    function _expected_facetAddress(IERC8109Introspection subject, bytes4 selector) internal view returns (address) {
        return _layout().expected_facetAddress[subject][selector];
    }

    function _set_expected_facetAddress(
        Behavior_IERC8109IntrospectionLayout storage layout,
        IERC8109Introspection subject,
        bytes4 selector,
        address facet
    ) internal {
        layout.expected_facetAddress[subject][selector] = facet;
        layout.expected_selectors[subject]._add(selector);
    }

    function _set_expected_facetAddress(IERC8109Introspection subject, bytes4 selector, address facet) internal {
        _set_expected_facetAddress(_layout(), subject, selector, facet);
    }

    /* ------ Expected selectors ------ */

    function _expected_selectors(
        Behavior_IERC8109IntrospectionLayout storage layout,
        IERC8109Introspection subject
    ) internal view returns (Bytes4Set storage) {
        return layout.expected_selectors[subject];
    }

    function _expected_selectors(IERC8109Introspection subject) internal view returns (Bytes4Set storage) {
        return _layout().expected_selectors[subject];
    }
}

/* -------------------------------------------------------------------------- */
/*                              Behavior Library                              */
/* -------------------------------------------------------------------------- */

library Behavior_IERC8109Introspection {
    using BetterAddress for address;
    using Bytes4 for bytes4;
    using Bytes4SetRepo for Bytes4Set;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the name of the behavior for logging.
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IERC8109IntrospectionName() internal pure returns (string memory) {
        return type(Behavior_IERC8109Introspection).name;
    }

    /// @notice Returns the error prefix for a function.
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return BehaviorUtils._errPrefix(_Behavior_IERC8109IntrospectionName(), testedFuncSig, subjectLabel);
    }

    /// @notice Returns the error prefix for a function using address label.
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return BehaviorUtils._errPrefix(_Behavior_IERC8109IntrospectionName(), testedFuncSig, subject);
    }

    /* -------------------------------------------------------------------------- */
    /*                           facetAddress(bytes4)                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the function signature string for facetAddress.
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_facetAddress() internal pure returns (string memory) {
        return "facetAddress(bytes4)";
    }

    /// @notice Returns the error suffix for facetAddress.
    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_facetAddress() internal pure returns (string memory) {
        return "facet of function";
    }

    /// @notice Sets expectation for facetAddress for a single selector.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC8109Introspection_facetAddress(
        IERC8109Introspection subject,
        bytes4 selector,
        address expectedFacet
    ) internal {
        console.logBehaviorEntry(_Behavior_IERC8109IntrospectionName(), "expect_IERC8109Introspection_facetAddress");

        Behavior_IERC8109IntrospectionRepo._set_expected_facetAddress(subject, selector, expectedFacet);

        console.logBehaviorExpectation(
            _Behavior_IERC8109IntrospectionName(),
            "expect_IERC8109Introspection_facetAddress",
            string.concat("selector: ", selector._toHexString()),
            vm.getLabel(expectedFacet)
        );

        console.logBehaviorExit(_Behavior_IERC8109IntrospectionName(), "expect_IERC8109Introspection_facetAddress");
    }

    /// @notice Sets expectation for facetAddress for multiple selectors pointing to the same facet.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC8109Introspection_facetAddress(
        IERC8109Introspection subject,
        bytes4[] memory selectors,
        address expectedFacet
    ) internal {
        for (uint256 i = 0; i < selectors.length; i++) {
            expect_IERC8109Introspection_facetAddress(subject, selectors[i], expectedFacet);
        }
    }

    /// @notice Validates that facetAddress returns the expected value for a selector.
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IERC8109Introspection_facetAddress(
        string memory subjectLabel,
        bytes4 selector,
        address expected,
        address actual
    ) internal view returns (bool isValid) {
        console.logBehaviorEntry(
            _Behavior_IERC8109IntrospectionName(), "areValid_IERC8109Introspection_facetAddress"
        );

        isValid = expected == actual;

        if (!isValid) {
            console.logBehaviorError(
                _Behavior_IERC8109IntrospectionName(),
                "areValid_IERC8109Introspection_facetAddress",
                _errPrefix(funcSig_facetAddress(), subjectLabel),
                string.concat("Facet mismatch for selector ", selector._toHexString())
            );
            console.logCompare(
                subjectLabel,
                string.concat("selector: ", selector._toHexString()),
                vm.getLabel(expected),
                vm.getLabel(actual)
            );
        }

        console.logBehaviorValidation(
            _Behavior_IERC8109IntrospectionName(),
            "areValid_IERC8109Introspection_facetAddress",
            string.concat("selector ", selector._toHexString()),
            isValid
        );

        console.logBehaviorExit(
            _Behavior_IERC8109IntrospectionName(), "areValid_IERC8109Introspection_facetAddress"
        );
    }

    /// @notice Validates that facetAddress returns the expected value for a selector (using subject address).
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IERC8109Introspection_facetAddress(
        IERC8109Introspection subject,
        bytes4 selector,
        address expected,
        address actual
    ) internal view returns (bool) {
        return areValid_IERC8109Introspection_facetAddress(vm.getLabel(address(subject)), selector, expected, actual);
    }

    /// @notice Validates all expected facetAddress mappings for a subject.
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IERC8109Introspection_facetAddress(IERC8109Introspection subject)
        internal
        view
        returns (bool isValid)
    {
        console.logBehaviorEntry(_Behavior_IERC8109IntrospectionName(), "hasValid_IERC8109Introspection_facetAddress");

        isValid = true;
        Bytes4Set storage expectedSelectors = Behavior_IERC8109IntrospectionRepo._expected_selectors(subject);
        uint256 count = expectedSelectors._length();

        console.logBehaviorValidation(
            _Behavior_IERC8109IntrospectionName(),
            "hasValid_IERC8109Introspection_facetAddress",
            "expected selector count",
            count > 0
        );

        for (uint256 i = 0; i < count; i++) {
            bytes4 selector = expectedSelectors._index(i);
            address expectedFacet = Behavior_IERC8109IntrospectionRepo._expected_facetAddress(subject, selector);
            address actualFacet = subject.facetAddress(selector);

            bool valid = areValid_IERC8109Introspection_facetAddress(subject, selector, expectedFacet, actualFacet);
            if (!valid) {
                isValid = false;
            }
        }

        console.logBehaviorValidation(
            _Behavior_IERC8109IntrospectionName(),
            "hasValid_IERC8109Introspection_facetAddress",
            "all facetAddress mappings",
            isValid
        );

        console.logBehaviorExit(_Behavior_IERC8109IntrospectionName(), "hasValid_IERC8109Introspection_facetAddress");
    }

    /* -------------------------------------------------------------------------- */
    /*                            functionFacetPairs()                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Returns the function signature string for functionFacetPairs.
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_functionFacetPairs() internal pure returns (string memory) {
        return "functionFacetPairs()";
    }

    /// @notice Returns the error suffix for functionFacetPairs.
    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_functionFacetPairs() internal pure returns (string memory) {
        return "function-facet pairs";
    }

    /// @notice Sets expectations from an array of FunctionFacetPair structs.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC8109Introspection_functionFacetPairs(
        IERC8109Introspection subject,
        IERC8109Introspection.FunctionFacetPair[] memory expectedPairs
    ) internal {
        console.logBehaviorEntry(
            _Behavior_IERC8109IntrospectionName(), "expect_IERC8109Introspection_functionFacetPairs"
        );

        for (uint256 i = 0; i < expectedPairs.length; i++) {
            expect_IERC8109Introspection_facetAddress(
                subject, expectedPairs[i].selector, expectedPairs[i].facet
            );
        }

        console.logBehaviorExpectation(
            _Behavior_IERC8109IntrospectionName(),
            "expect_IERC8109Introspection_functionFacetPairs",
            "pairs count",
            expectedPairs.length._toString()
        );

        console.logBehaviorExit(
            _Behavior_IERC8109IntrospectionName(), "expect_IERC8109Introspection_functionFacetPairs"
        );
    }

    /// @notice Validates that functionFacetPairs returns expected pairs.
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IERC8109Introspection_functionFacetPairs(
        IERC8109Introspection subject,
        IERC8109Introspection.FunctionFacetPair[] memory expected,
        IERC8109Introspection.FunctionFacetPair[] memory actual
    ) internal view returns (bool isValid) {
        console.logBehaviorEntry(
            _Behavior_IERC8109IntrospectionName(), "areValid_IERC8109Introspection_functionFacetPairs"
        );

        isValid = true;

        // Check count matches
        if (expected.length != actual.length) {
            console.logBehaviorError(
                _Behavior_IERC8109IntrospectionName(),
                "areValid_IERC8109Introspection_functionFacetPairs",
                _errPrefix(funcSig_functionFacetPairs(), vm.getLabel(address(subject))),
                "Pair count mismatch"
            );
            console.logCompare(
                vm.getLabel(address(subject)),
                "pair count",
                expected.length._toString(),
                actual.length._toString()
            );
            isValid = false;
        }

        // Build lookup from actual pairs
        // For each expected pair, verify it exists in actual
        for (uint256 i = 0; i < expected.length && isValid; i++) {
            bool found = false;
            for (uint256 j = 0; j < actual.length; j++) {
                if (expected[i].selector == actual[j].selector) {
                    found = true;
                    if (expected[i].facet != actual[j].facet) {
                        console.logBehaviorError(
                            _Behavior_IERC8109IntrospectionName(),
                            "areValid_IERC8109Introspection_functionFacetPairs",
                            _errPrefix(funcSig_functionFacetPairs(), vm.getLabel(address(subject))),
                            string.concat("Facet mismatch for selector ", expected[i].selector._toHexString())
                        );
                        console.logCompare(
                            vm.getLabel(address(subject)),
                            string.concat("selector: ", expected[i].selector._toHexString()),
                            vm.getLabel(expected[i].facet),
                            vm.getLabel(actual[j].facet)
                        );
                        isValid = false;
                    }
                    break;
                }
            }
            if (!found) {
                console.logBehaviorError(
                    _Behavior_IERC8109IntrospectionName(),
                    "areValid_IERC8109Introspection_functionFacetPairs",
                    _errPrefix(funcSig_functionFacetPairs(), vm.getLabel(address(subject))),
                    string.concat("Missing selector in actual: ", expected[i].selector._toHexString())
                );
                isValid = false;
            }
        }

        console.logBehaviorValidation(
            _Behavior_IERC8109IntrospectionName(),
            "areValid_IERC8109Introspection_functionFacetPairs",
            "function-facet pairs",
            isValid
        );

        console.logBehaviorExit(
            _Behavior_IERC8109IntrospectionName(), "areValid_IERC8109Introspection_functionFacetPairs"
        );
    }

    /// @notice Validates functionFacetPairs against stored expectations.
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IERC8109Introspection_functionFacetPairs(IERC8109Introspection subject)
        internal
        view
        returns (bool isValid)
    {
        console.logBehaviorEntry(
            _Behavior_IERC8109IntrospectionName(), "hasValid_IERC8109Introspection_functionFacetPairs"
        );

        isValid = true;
        IERC8109Introspection.FunctionFacetPair[] memory actual = subject.functionFacetPairs();
        Bytes4Set storage expectedSelectors = Behavior_IERC8109IntrospectionRepo._expected_selectors(subject);
        uint256 expectedCount = expectedSelectors._length();

        // Check count
        if (expectedCount != actual.length) {
            console.logBehaviorError(
                _Behavior_IERC8109IntrospectionName(),
                "hasValid_IERC8109Introspection_functionFacetPairs",
                _errPrefix(funcSig_functionFacetPairs(), vm.getLabel(address(subject))),
                "Pair count mismatch"
            );
            console.logCompare(
                vm.getLabel(address(subject)),
                "pair count",
                expectedCount._toString(),
                actual.length._toString()
            );
            isValid = false;
        }

        // Validate each expected selector exists in actual with correct facet
        for (uint256 i = 0; i < expectedCount && isValid; i++) {
            bytes4 selector = expectedSelectors._index(i);
            address expectedFacet = Behavior_IERC8109IntrospectionRepo._expected_facetAddress(subject, selector);

            bool found = false;
            for (uint256 j = 0; j < actual.length; j++) {
                if (actual[j].selector == selector) {
                    found = true;
                    if (actual[j].facet != expectedFacet) {
                        console.logBehaviorError(
                            _Behavior_IERC8109IntrospectionName(),
                            "hasValid_IERC8109Introspection_functionFacetPairs",
                            _errPrefix(funcSig_functionFacetPairs(), vm.getLabel(address(subject))),
                            string.concat("Facet mismatch for selector ", selector._toHexString())
                        );
                        isValid = false;
                    }
                    break;
                }
            }
            if (!found) {
                console.logBehaviorError(
                    _Behavior_IERC8109IntrospectionName(),
                    "hasValid_IERC8109Introspection_functionFacetPairs",
                    _errPrefix(funcSig_functionFacetPairs(), vm.getLabel(address(subject))),
                    string.concat("Missing selector in actual: ", selector._toHexString())
                );
                isValid = false;
            }
        }

        console.logBehaviorValidation(
            _Behavior_IERC8109IntrospectionName(),
            "hasValid_IERC8109Introspection_functionFacetPairs",
            "all function-facet pairs",
            isValid
        );

        console.logBehaviorExit(
            _Behavior_IERC8109IntrospectionName(), "hasValid_IERC8109Introspection_functionFacetPairs"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Combined Validation                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Sets all expectations for IERC8109Introspection from pairs.
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC8109Introspection(
        IERC8109Introspection subject,
        IERC8109Introspection.FunctionFacetPair[] memory expectedPairs
    ) internal {
        console.logBehaviorEntry(_Behavior_IERC8109IntrospectionName(), "expect_IERC8109Introspection");

        expect_IERC8109Introspection_functionFacetPairs(subject, expectedPairs);

        console.logBehaviorExit(_Behavior_IERC8109IntrospectionName(), "expect_IERC8109Introspection");
    }

    /// @notice Validates all IERC8109Introspection behavior.
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IERC8109Introspection(IERC8109Introspection subject) internal view returns (bool isValid) {
        console.logBehaviorEntry(_Behavior_IERC8109IntrospectionName(), "hasValid_IERC8109Introspection");

        isValid = true;

        // Validate facetAddress for all expected selectors
        if (!hasValid_IERC8109Introspection_facetAddress(subject)) {
            isValid = false;
        }

        // Validate functionFacetPairs returns expected pairs
        if (!hasValid_IERC8109Introspection_functionFacetPairs(subject)) {
            isValid = false;
        }

        console.logBehaviorValidation(
            _Behavior_IERC8109IntrospectionName(),
            "hasValid_IERC8109Introspection",
            "full IERC8109Introspection interface",
            isValid
        );

        console.logBehaviorExit(_Behavior_IERC8109IntrospectionName(), "hasValid_IERC8109Introspection");
    }
}
