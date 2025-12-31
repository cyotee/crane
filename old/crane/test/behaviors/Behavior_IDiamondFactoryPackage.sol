// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Forge                                   */
/* -------------------------------------------------------------------------- */

import {VmSafe} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {Behavior} from "contracts/crane/test/behaviors/Behavior.sol";
// import { FoundryVM } from "contracts/crane/utils/vm/foundry/FoundryVM.sol";
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
import {FacetsComparator} from "contracts/crane/test/comparators/erc2535/FacetsComparator.sol";
import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondLoupe} from "contracts/crane/interfaces/IDiamondLoupe.sol";
import {
    DiamondFactoryPackageAdaptor
} from "contracts/crane/factories/create2/callback/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol";
import {IDiamond} from "contracts/crane/interfaces/IDiamond.sol";

/**
 * @title Behavior_IDiamondFactoryPackage
 * @notice Behavior contract for testing IDiamondFactoryPackage implementations
 * @dev Validates that contracts correctly implement the IDiamondFactoryPackage interface
 *      by checking facet configurations, diamond configs, and package processing.
 *      This contract is crucial for ensuring diamond factory packages are correctly
 *      configured and exposed.
 */
contract Behavior_IDiamondFactoryPackage is
    Behavior,
    // AddressSetComparator,
    // Bytes4SetComparator
    FacetsComparator
{
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

    using DiamondFactoryPackageAdaptor for IDiamondFactoryPackage;

    /* ------------------------- State Variables ---------------------------- */
    mapping(
        IDiamondFactoryPackage subject => mapping(address facet => IDiamond.FacetCutAction action)
        /// forge-lint: disable-next-line(mixed-case-variable)
    ) private _expected_action;

    /// forge-lint: disable-next-line(mixed-case-variable)
    mapping(address subject => CalcSaltExpect[] expected) private _expected_salt;
    /// forge-lint: disable-next-line(mixed-case-variable)
    mapping(address subject => ProcessArgsExpect[] expected) private _expected_args;

    /* ------------------------- Helper Functions --------------------------- */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _idfPKG_behaviorName() internal pure returns (string memory) {
        return type(Behavior_IDiamondFactoryPackage).name;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _idfPKG_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        view
        virtual
        returns (string memory)
    {
        return _errPrefix(_idfPKG_behaviorName(), testedFuncSig, subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _idfPKG_errPrefix(string memory testedFuncSig, address subject)
        internal
        view
        virtual
        returns (string memory)
    {
        return _errPrefix(_idfPKG_behaviorName(), testedFuncSig, subject);
    }

    /* ------------------------- Interface Functions ------------------------ */

    /* -------------------------- facetInterfaces() ------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IDiamondFactoryPackage_facetInterfaces() public pure returns (string memory) {
        return "facetInterfaces()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IDiamondFactoryPackage_facetInterfaces() public pure returns (string memory) {
        return "interface IDs";
    }

    /**
     * @notice Validates a package's interface IDs against expectations
     * @param subjectLabel The name/label of the contract being tested
     * @param expected The expected interface IDs
     * @param actual The actual interface IDs
     * @return valid True if the interface IDs match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondFactoryPackage_facetInterfaces(
        string memory subjectLabel,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) public returns (bool valid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "areValid_IDiamondFactoryPackage_facetInterfaces");

        valid = _compare(
            expected,
            actual,
            _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_facetInterfaces(), subjectLabel),
            errSuffix_IDiamondFactoryPackage_facetInterfaces()
        );

        console.logBehaviorValidation(
            _idfPKG_behaviorName(), "areValid_IDiamondFactoryPackage_facetInterfaces", "interface IDs", valid
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "areValid_IDiamondFactoryPackage_facetInterfaces");
        return valid;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondFactoryPackage_facetInterfaces(
        IDiamondFactoryPackage subject,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) public returns (bool valid) {
        return areValid_IDiamondFactoryPackage_facetInterfaces(vm.getLabel(address(subject)), expected, actual);
    }

    /**
     * @notice Sets expectations for a package's interface IDs
     * @param subject The package contract to test
     * @param expectedInterfaces_ The expected interface IDs
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondFactoryPackage_facetInterfaces(
        IDiamondFactoryPackage subject,
        bytes4[] memory expectedInterfaces_
    ) public {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_facetInterfaces");

        _recExpectedBytes4(address(subject), IDiamondFactoryPackage.facetInterfaces.selector, expectedInterfaces_);

        console.logBehaviorExpectation(
            _idfPKG_behaviorName(),
            "expect_IDiamondFactoryPackage_facetInterfaces",
            "interface count",
            expectedInterfaces_.length.toString()
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_facetInterfaces");
    }

    /**
     * @notice Validates that a package's current interface IDs match expectations
     * @param subject The package contract to test
     * @return isValid_ True if the interface IDs match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondFactoryPackage_facetInterfaces(IDiamondFactoryPackage subject)
        public
        returns (bool isValid_)
    {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_facetInterfaces");

        isValid_ = areValid_IDiamondFactoryPackage_facetInterfaces(
            subject,
            _recedExpectedBytes4(address(subject), IDiamondFactoryPackage.facetInterfaces.selector)._values(),
            subject.facetInterfaces()
        );

        console.logBehaviorValidation(
            _idfPKG_behaviorName(),
            "hasValid_IDiamondFactoryPackage_facetInterfaces",
            "interface configuration",
            isValid_
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_facetInterfaces");
    }

    /* ----------------------------- facetCuts() ---------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IDiamondFactoryPackage_facetCuts() public pure returns (string memory) {
        return "facetCuts()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IDiamondFactoryPackage_facetCuts() public pure returns (string memory) {
        return "facets";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IDiamondFactoryPackage_facets_funcs(string memory facetLabel)
        public
        pure
        returns (string memory)
    {
        return string.concat("facet functions for facet ", facetLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IDiamondFactoryPackage_facets_funcs(IDiamondFactoryPackage subject)
        public
        view
        returns (string memory)
    {
        return string.concat("facets functions for facet ", vm.getLabel(address(subject)));
    }

    /**
     * @notice Processes facet cuts into facet arrays for comparison
     * @param subject The package contract being tested
     * @param expected The expected facet cuts
     * @param actual The actual facet cuts
     * @return expectedFacets The processed expected facets
     * @return actualFacets The processed actual facets
     */
    function _procFacetCuts(
        IDiamondFactoryPackage subject,
        IDiamond.FacetCut[] memory expected,
        IDiamond.FacetCut[] memory actual
    ) internal returns (IDiamondLoupe.Facet[] memory expectedFacets, IDiamondLoupe.Facet[] memory actualFacets) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "_procFacetCuts");

        expectedFacets = new IDiamondLoupe.Facet[](expected.length);
        actualFacets = new IDiamondLoupe.Facet[](actual.length);

        for (uint256 expectedCursor = 0; expectedCursor < expected.length; expectedCursor++) {
            console.logBehaviorProcessing(_idfPKG_behaviorName(), "_procFacetCuts", "facet", expectedCursor.toString());

            expectedFacets[expectedCursor] = IDiamondLoupe.Facet({
                facetAddress: expected[expectedCursor].facetAddress,
                functionSelectors: expected[expectedCursor].functionSelectors
            });
            actualFacets[expectedCursor] = IDiamondLoupe.Facet({
                facetAddress: actual[expectedCursor].facetAddress,
                functionSelectors: actual[expectedCursor].functionSelectors
            });

            _recFacet(
                IDiamondLoupe(address(subject)),
                expected[expectedCursor].facetAddress,
                expected[expectedCursor].functionSelectors
            );
        }

        console.logBehaviorExit(_idfPKG_behaviorName(), "_procFacetCuts");
    }

    /**
     * @notice Validates a package's facet cuts against expectations
     * @param subject The package contract to test
     * @param expected The expected facet cuts
     * @param actual The actual facet cuts
     * @return isValid True if the facet cuts match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondLoupe_facetCuts(
        IDiamondFactoryPackage subject,
        IDiamond.FacetCut[] memory expected,
        IDiamond.FacetCut[] memory actual
    ) public returns (bool isValid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "areValid_IDiamondLoupe_facetCuts");

        isValid = true;
        if (expected.length != actual.length) {
            _logLengthMismatch(
                expected.length,
                actual.length,
                _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_facetCuts(), vm.getLabel(address(subject))),
                errSuffix_IDiamondFactoryPackage_facetCuts()
            );
            isValid = false;
        }

        IDiamondLoupe.Facet[] memory expectedFacets;
        IDiamondLoupe.Facet[] memory actualFacets;
        (expectedFacets, actualFacets) = _procFacetCuts(subject, expected, actual);

        bool facetsValid = _compareFacets(
            IDiamondLoupe(address(subject)),
            expectedFacets,
            actualFacets,
            _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_facetCuts(), vm.getLabel(address(subject))),
            errSuffix_IDiamondFactoryPackage_facetCuts(),
            errSuffix_IDiamondFactoryPackage_facets_funcs(vm.getLabel(address(subject)))
        );

        isValid = isValid && facetsValid;

        console.logBehaviorValidation(_idfPKG_behaviorName(), "areValid_IDiamondLoupe_facetCuts", "facet cuts", isValid);

        console.logBehaviorExit(_idfPKG_behaviorName(), "areValid_IDiamondLoupe_facetCuts");
    }

    /* --------------------------- diamondConfig() -------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IDiamondFactoryPackage_diamondConfig() public pure returns (string memory) {
        return "diamondConfig()";
    }

    /**
     * @notice Evaluates a package's facet interfaces against expectations
     * @param subject The package contract to test
     * @param expected The expected diamond config
     * @param actual The actual diamond config
     * @return isValid True if the interfaces match expectations
     */
    function _evalFacetInterfaces(
        IDiamondFactoryPackage subject,
        IDiamondFactoryPackage.DiamondConfig memory expected,
        IDiamondFactoryPackage.DiamondConfig memory actual
    ) internal returns (bool isValid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "_evalFacetInterfaces");

        isValid = _compare(
            expected.interfaces,
            actual.interfaces,
            _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_diamondConfig(), vm.getLabel(address(subject))),
            errSuffix_IDiamondFactoryPackage_facetInterfaces()
        );

        console.logBehaviorValidation(_idfPKG_behaviorName(), "_evalFacetInterfaces", "interfaces", isValid);

        console.logBehaviorExit(_idfPKG_behaviorName(), "_evalFacetInterfaces");
    }

    /**
     * @notice Evaluates a package's diamond config against expectations
     * @param subject The package contract to test
     * @param expected The expected diamond config
     * @param actual The actual diamond config
     * @return isValid True if the config matches expectations
     * @return expectedFacets The processed expected facets
     * @return actualFacets The processed actual facets
     */
    function _evalDiamondConfig(
        IDiamondFactoryPackage subject,
        IDiamondFactoryPackage.DiamondConfig memory expected,
        IDiamondFactoryPackage.DiamondConfig memory actual
    )
        internal
        returns (bool isValid, IDiamondLoupe.Facet[] memory expectedFacets, IDiamondLoupe.Facet[] memory actualFacets)
    {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "_evalDiamondConfig");

        isValid = true;

        console.logBehaviorProcessing(
            _idfPKG_behaviorName(),
            "_evalDiamondConfig",
            "facet counts",
            string.concat(
                "expected: ", expected.facetCuts.length.toString(), ", actual: ", actual.facetCuts.length.toString()
            )
        );

        expectedFacets = new IDiamondLoupe.Facet[](expected.facetCuts.length);
        actualFacets = new IDiamondLoupe.Facet[](actual.facetCuts.length);

        for (uint256 expectedCursor = 0; expectedCursor < expected.facetCuts.length; expectedCursor++) {
            console.logBehaviorProcessing(
                _idfPKG_behaviorName(), "_evalDiamondConfig", "facet", expectedCursor.toString()
            );

            expectedFacets[expectedCursor] = IDiamondLoupe.Facet({
                facetAddress: expected.facetCuts[expectedCursor].facetAddress,
                functionSelectors: expected.facetCuts[expectedCursor].functionSelectors
            });
            actualFacets[expectedCursor] = IDiamondLoupe.Facet({
                facetAddress: actual.facetCuts[expectedCursor].facetAddress,
                functionSelectors: actual.facetCuts[expectedCursor].functionSelectors
            });

            bool actionCheck = expected.facetCuts[expectedCursor].action == actual.facetCuts[expectedCursor].action;
            isValid = isValid && actionCheck;

            if (!actionCheck) {
                console.logBehaviorError(
                    _idfPKG_behaviorName(),
                    "_evalDiamondConfig",
                    "Action mismatch",
                    string.concat("Facet: ", vm.getLabel(expected.facetCuts[expectedCursor].facetAddress))
                );
            }

            bool funcCheck = _compare(
                expectedFacets[expectedCursor].functionSelectors,
                actualFacets[expectedCursor].functionSelectors,
                _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_diamondConfig(), vm.getLabel(address(subject))),
                errSuffix_IDiamondFactoryPackage_facets_funcs(vm.getLabel(address(subject)))
            );

            isValid = isValid && funcCheck;
        }

        console.logBehaviorValidation(_idfPKG_behaviorName(), "_evalDiamondConfig", "diamond config", isValid);

        console.logBehaviorExit(_idfPKG_behaviorName(), "_evalDiamondConfig");
    }

    function _diamondConfigErPrefix(IDiamondFactoryPackage subject) internal view returns (string memory) {
        return _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_diamondConfig(), vm.getLabel(address(subject)));
    }

    /**
     * @notice Evaluates a package's facets against expectations
     * @param subject The package contract to test
     * @param expectedFacets The expected facets
     * @param actualFacets The actual facets
     * @return isValid True if the facets match expectations
     */
    function _evalFacets(
        IDiamondFactoryPackage subject,
        IDiamondLoupe.Facet[] memory expectedFacets,
        IDiamondLoupe.Facet[] memory actualFacets
    ) internal returns (bool isValid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "_evalFacets");

        isValid = _compareFacets(
            IDiamondLoupe(address(subject)),
            expectedFacets,
            actualFacets,
            _diamondConfigErPrefix(subject),
            errSuffix_IDiamondFactoryPackage_facetCuts(),
            errSuffix_IDiamondFactoryPackage_facets_funcs(vm.getLabel(address(subject)))
        );

        console.logBehaviorValidation(_idfPKG_behaviorName(), "_evalFacets", "facets", isValid);

        console.logBehaviorExit(_idfPKG_behaviorName(), "_evalFacets");
    }

    /**
     * @notice Validates a package's diamond config against expectations
     * @param subject The package contract to test
     * @param expected The expected diamond config
     * @param actual The actual diamond config
     * @return isValid True if the config matches expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondFactoryPackage_diamondConfig(
        IDiamondFactoryPackage subject,
        IDiamondFactoryPackage.DiamondConfig memory expected,
        IDiamondFactoryPackage.DiamondConfig memory actual
    ) public returns (bool isValid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "areValid_IDiamondFactoryPackage_diamondConfig");

        isValid = _evalFacetInterfaces(subject, expected, actual);

        IDiamondLoupe.Facet[] memory expectedFacets;
        IDiamondLoupe.Facet[] memory actualFacets;
        bool configValid;

        (configValid, expectedFacets, actualFacets) = _evalDiamondConfig(subject, expected, actual);

        bool facetsValid = _evalFacets(subject, expectedFacets, actualFacets);

        isValid = isValid && configValid && facetsValid;

        console.logBehaviorValidation(
            _idfPKG_behaviorName(), "areValid_IDiamondFactoryPackage_diamondConfig", "full config", isValid
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "areValid_IDiamondFactoryPackage_diamondConfig");
    }

    /**
     * @notice Sets expectations for a package's diamond config
     * @param subject The package contract to test
     * @param expected The expected diamond config
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondFactoryPackage_diamondConfig(
        IDiamondFactoryPackage subject,
        IDiamondFactoryPackage.DiamondConfig memory expected
    ) public {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_diamondConfig");

        IDiamondLoupe.Facet[] memory expectedFacets = new IDiamondLoupe.Facet[](expected.facetCuts.length);

        for (uint256 expectedCursor = 0; expectedCursor < expected.facetCuts.length; expectedCursor++) {
            expectedFacets[expectedCursor] = IDiamondLoupe.Facet({
                facetAddress: expected.facetCuts[expectedCursor].facetAddress,
                functionSelectors: expected.facetCuts[expectedCursor].functionSelectors
            });

            _recFacet(
                IDiamondLoupe(address(subject)),
                expectedFacets[expectedCursor].facetAddress,
                expectedFacets[expectedCursor].functionSelectors
            );

            _expected_action[subject][expectedFacets[expectedCursor].facetAddress] =
            expected.facetCuts[expectedCursor].action;

            console.logBehaviorExpectation(
                _idfPKG_behaviorName(),
                "expect_IDiamondFactoryPackage_diamondConfig",
                "facet",
                vm.getLabel(expectedFacets[expectedCursor].facetAddress)
            );
        }

        _recExpectedBytes4(address(subject), IDiamondFactoryPackage.diamondConfig.selector, expected.interfaces);

        console.logBehaviorExit(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_diamondConfig");
    }

    /**
     * @notice Gets the expected diamond config for a package
     * @param subject The package contract to test
     * @return expected The expected diamond config
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IDiamondFactoryPackage_diamondConfig(IDiamondFactoryPackage subject)
        public
        view
        returns (IDiamondFactoryPackage.DiamondConfig memory expected)
    {
        IDiamondLoupe.Facet[] memory expectedFacets = _expectedFacets(IDiamondLoupe(address(subject)));
        expected.facetCuts = new IDiamond.FacetCut[](expectedFacets.length);

        for (uint256 facetsCursor = 0; facetsCursor < expectedFacets.length; facetsCursor++) {
            expected.facetCuts[facetsCursor] = IDiamond.FacetCut({
                facetAddress: expectedFacets[facetsCursor].facetAddress,
                action: _expected_action[subject][expectedFacets[facetsCursor].facetAddress],
                functionSelectors: expectedFacets[facetsCursor].functionSelectors
            });
        }

        expected.interfaces =
            _recedExpectedBytes4(address(subject), IDiamondFactoryPackage.diamondConfig.selector)._values();
    }

    /**
     * @notice Validates that a package's current diamond config matches expectations
     * @param subject The package contract to test
     * @return isValid True if the config matches expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondFactoryPackage_diamondConfig(IDiamondFactoryPackage subject)
        public
        returns (bool isValid)
    {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_diamondConfig");

        isValid = areValid_IDiamondFactoryPackage_diamondConfig(
            subject, expected_IDiamondFactoryPackage_diamondConfig(subject), subject.diamondConfig()
        );

        console.logBehaviorValidation(
            _idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_diamondConfig", "diamond config", isValid
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_diamondConfig");
    }

    /* --------------------------- calcSalt(bytes) -------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IDiamondFactoryPackage_calcSalt() public pure returns (string memory) {
        return "calcSalt(bytes)";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IDiamondFactoryPackage_calcSalt() public pure returns (string memory) {
        return "salt";
    }

    /**
     * @notice Validates a package's salt calculation against expectations
     * @param subjectLabel The name/label of the contract being tested
     * @param expected The expected salt
     * @param actual The actual salt
     * @return isValid True if the salt matches expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondFactoryPackage_calcSalt(string memory subjectLabel, bytes32 expected, bytes32 actual)
        public
        view
        returns (bool isValid)
    {
        isValid = expected == actual;

        if (!isValid) {
            console.logBehaviorError(
                _idfPKG_behaviorName(),
                "areValid_IDiamondFactoryPackage_calcSalt",
                string.concat(
                    _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_calcSalt(), subjectLabel),
                    " UNEXPECTED ",
                    errSuffix_IDiamondFactoryPackage_calcSalt(),
                    "."
                ),
                ""
            );

            console.logCompare(subjectLabel, "", expected, actual);
        }
    }

    struct CalcSaltExpect {
        address sender;
        bytes args;
        bytes32 salt;
    }

    /**
     * @notice Sets expectations for a package's salt calculation
     * @param subject The package contract to test
     * @param expectedSender The expected sender address
     * @param expectedArgs The expected package arguments
     * @param expectedSalt The expected salt value
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondFactoryPackage_calcSalt(
        IDiamondFactoryPackage subject,
        address expectedSender,
        bytes memory expectedArgs,
        bytes32 expectedSalt
    ) public {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_calcSalt");

        _expected_salt[address(
                subject
            )].push(CalcSaltExpect({sender: expectedSender, args: expectedArgs, salt: expectedSalt}));

        console.logBehaviorExpectation(
            _idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_calcSalt", "sender", vm.getLabel(expectedSender)
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_calcSalt");
    }

    /**
     * @notice Gets the expected salt calculations for a package
     * @param subject The package contract to test
     * @return The array of expected salt calculations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IDiamondFactoryPackage_calcSalt(IDiamondFactoryPackage subject)
        public
        view
        returns (CalcSaltExpect[] memory)
    {
        return _expected_salt[address(subject)];
    }

    /**
     * @notice Validates that a package's current salt calculations match expectations
     * @param subject The package contract to test
     * @return isValid True if all salt calculations match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondFactoryPackage_calcSalt(IDiamondFactoryPackage subject) public returns (bool isValid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_calcSalt");

        isValid = true;
        (VmSafe.CallerMode mode, address msgSender,) = vm.readCallers();
        CalcSaltExpect[] memory expected = expected_IDiamondFactoryPackage_calcSalt(subject);

        for (uint256 cursor = 0; cursor < expected.length; cursor++) {
            console.logBehaviorProcessing(
                _idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_calcSalt", "expectation", cursor.toString()
            );

            if (mode == VmSafe.CallerMode.None) {
                vm.startPrank(expected[cursor].sender);
            }
            if (mode == VmSafe.CallerMode.Broadcast || mode == VmSafe.CallerMode.RecurrentBroadcast) {
                msgSender = msg.sender;
                vm.stopBroadcast();
                vm.broadcast(expected[cursor].sender);
            }
            if (mode == VmSafe.CallerMode.Prank || mode == VmSafe.CallerMode.RecurrentPrank) {
                vm.stopPrank();
                vm.prank(expected[cursor].sender);
            }

            bool result = areValid_IDiamondFactoryPackage_calcSalt(
                vm.getLabel(address(subject)), expected[cursor].salt, subject._calcSalt(expected[cursor].args)
            );

            if (isValid) {
                isValid = result;
            }
        }

        if (mode == VmSafe.CallerMode.None) {
            vm.stopPrank();
        }
        if (mode == VmSafe.CallerMode.Broadcast || mode == VmSafe.CallerMode.RecurrentBroadcast) {
            vm.broadcast(msgSender);
        }
        if (mode == VmSafe.CallerMode.Prank || mode == VmSafe.CallerMode.RecurrentPrank) {
            vm.prank(msgSender);
        }

        console.logBehaviorValidation(
            _idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_calcSalt", "salt calculations", isValid
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_calcSalt");
        return isValid;
    }

    /* ------------------------- processArgs(bytes) ------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IDiamondFactoryPackage_processArgs() public pure returns (string memory) {
        return "processArgs(bytes)";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IDiamondFactoryPackage_processArgs() public pure returns (string memory) {
        return "processed args";
    }

    /**
     * @notice Validates a package's argument processing against expectations
     * @param subjectLabel The name/label of the contract being tested
     * @param expected The expected processed arguments
     * @param actual The actual processed arguments
     * @return isValid True if the processed arguments match expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondFactoryPackage_processArgs(
        string memory subjectLabel,
        bytes memory expected,
        bytes memory actual
    ) public view returns (bool isValid) {
        isValid = keccak256(expected) == keccak256(actual);

        if (!isValid) {
            console.logBehaviorError(
                _idfPKG_behaviorName(),
                "areValid_IDiamondFactoryPackage_processArgs",
                string.concat(
                    _idfPKG_errPrefix(funcSig_IDiamondFactoryPackage_processArgs(), subjectLabel),
                    " UNEXPECTED processed args."
                ),
                ""
            );

            console.logCompare(subjectLabel, "", string(expected), string(actual));
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IDiamondFactoryPackage_processArgs(
        IDiamondFactoryPackage subject,
        bytes memory expected,
        bytes memory actual
    ) public view returns (bool isValid) {
        return areValid_IDiamondFactoryPackage_processArgs(vm.getLabel(address(subject)), expected, actual);
    }

    struct ProcessArgsExpect {
        address sender;
        bytes args;
        bytes result;
    }

    /**
     * @notice Sets expectations for a package's argument processing
     * @param subject The package contract to test
     * @param expectedSender The expected sender address
     * @param expectedArgs The expected package arguments
     * @param result The expected processed arguments
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IDiamondFactoryPackage_processArgs(
        IDiamondFactoryPackage subject,
        address expectedSender,
        bytes memory expectedArgs,
        bytes memory result
    ) public {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_processArgs");

        _expected_args[address(
                subject
            )].push(ProcessArgsExpect({sender: expectedSender, args: expectedArgs, result: result}));

        console.logBehaviorExpectation(
            _idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_processArgs", "sender", vm.getLabel(expectedSender)
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "expect_IDiamondFactoryPackage_processArgs");
    }

    /**
     * @notice Gets the expected argument processing results for a package
     * @param subject The package contract to test
     * @return The array of expected argument processing results
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IDiamondFactoryPackage_processArgs(IDiamondFactoryPackage subject)
        public
        view
        returns (ProcessArgsExpect[] memory)
    {
        return _expected_args[address(subject)];
    }

    /**
     * @notice Validates that a package's current argument processing matches expectations
     * @param subject The package contract to test
     * @return isValid True if all argument processing matches expectations
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IDiamondFactoryPackage_processArgs(IDiamondFactoryPackage subject) public returns (bool isValid) {
        console.logBehaviorEntry(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_processArgs");

        isValid = true;
        (VmSafe.CallerMode mode, address msgSender,) = vm.readCallers();
        ProcessArgsExpect[] memory expected = expected_IDiamondFactoryPackage_processArgs(subject);

        for (uint256 cursor = 0; cursor < expected.length; cursor++) {
            console.logBehaviorProcessing(
                _idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_processArgs", "expectation", cursor.toString()
            );

            if (mode == VmSafe.CallerMode.None) {
                vm.startPrank(expected[cursor].sender);
            }
            if (mode == VmSafe.CallerMode.Broadcast || mode == VmSafe.CallerMode.RecurrentBroadcast) {
                msgSender = msg.sender;
                vm.stopBroadcast();
                vm.broadcast(expected[cursor].sender);
            }
            if (mode == VmSafe.CallerMode.Prank || mode == VmSafe.CallerMode.RecurrentPrank) {
                vm.stopPrank();
                vm.prank(expected[cursor].sender);
            }

            bool result = areValid_IDiamondFactoryPackage_processArgs(
                vm.getLabel(address(subject)), expected[cursor].result, subject._processArgs(expected[cursor].args)
            );

            if (isValid) {
                isValid = result;
            }
        }

        if (mode == VmSafe.CallerMode.None) {
            vm.stopPrank();
        }
        if (mode == VmSafe.CallerMode.Broadcast || mode == VmSafe.CallerMode.RecurrentBroadcast) {
            vm.broadcast(msgSender);
        }
        if (mode == VmSafe.CallerMode.Prank || mode == VmSafe.CallerMode.RecurrentPrank) {
            vm.prank(msgSender);
        }

        console.logBehaviorValidation(
            _idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_processArgs", "argument processing", isValid
        );

        console.logBehaviorExit(_idfPKG_behaviorName(), "hasValid_IDiamondFactoryPackage_processArgs");
        return isValid;
    }

    /* ------------------------- initAccount(bytes) ------------------------- */

    /* ------------------------- postDeploy(address) ------------------------ */
}
