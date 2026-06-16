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
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {Bytes4SetComparatorRepo, Bytes4SetComparator} from "@crane/contracts/test/comparators/Bytes4SetComparator.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";
import {StringComparatorRepo, StringComparator} from "@crane/contracts/test/comparators/StringComparator.sol";

// tag::Behavior_IFacet[]
/**
 * @title Behavior_IFacet
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Behavior library encapsulating validation logic for IFacet declaration compliance testing.
 * @dev Core for LR-7 facet declaration tests (via TestBase_IFacet and direct). Provides expect_*, hasValid_*, areValid_*, isValid_* helpers that delegate to comparators while logging via betterconsole.
 *      All IFacet surface references use ONLY the centrally computed values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md:
 *        facetName(): 0x5b6f4d01
 *        facetInterfaces(): 0x2ea80826
 *        facetFuncs(): 0x574a4cff
 *        facetMetadata(): 0xf10d7a75
 *      Pattern modeled directly on Behavior_IERC165 (error prefixes, _Name, funcSig, expect/hasValid/areValid/isValid), recent closed LR-1 Behavior tests (IFacet_Behavior_Test), TestBase_IFacet, AccessFacetFactoryService/InitDevService golds per AGENTS.md and PRD LR-1.
 *      No behavior or logic changes: console.logBehavior*, Bytes4SetComparatorRepo/StringComparatorRepo, UInt256 etc preserved exactly.
 *      "Storage" pattern N/A (pure behavior lib, not a Repo).
 */
library Behavior_IFacet {
    using Bytes4SetRepo for Bytes4Set;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::_Behavior_IFacetName()[]
    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IFacetName() internal pure returns (string memory) {
        return type(Behavior_IFacet).name;
    }
    // end::_Behavior_IFacetName()[]

    // tag::_ifacet_errPrefixFunc(string)[]
    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_Behavior_IFacetName(), testedFuncSig);
    }
    // end::_ifacet_errPrefixFunc(string)[]

    // tag::_ifacet_errPrefix(string-string)[]
    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_ifacet_errPrefixFunc(testedFuncSig), subjectLabel);
    }
    // end::_ifacet_errPrefix(string-string)[]

    // tag::_ifacet_errPrefix(string-address)[]
    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subject The address of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _ifacet_errPrefix(testedFuncSig, vm.getLabel(subject));
    }
    // end::_ifacet_errPrefix(string-address)[]

    // tag::expect_IFacet(IFacet-string-bytes4[]-bytes4[])[]

    /**
     * @notice Records expectations for a full IFacet declaration (name + interfaces + funcs) for later hasValid checks.
     * @dev Delegates to the per-component expect_ helpers. Used for comprehensive declaration testing of facets (LR-7).
     * @param subject The facet contract under test.
     * @param facetName The expected value for facetName().
     * @param expectedInterfaces_ The expected interface IDs array.
     * @param expectedFunc_ The expected function selectors array.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IFacet(
        IFacet subject,
        string memory facetName,
        bytes4[] memory expectedInterfaces_,
        bytes4[] memory expectedFunc_
    ) public {
        console.logBehaviorEntry(_Behavior_IFacetName(), "expect_IFacet");

        StringComparatorRepo._recExpectedString(address(subject), IFacet.facetName.selector, facetName);

        console.logBehaviorExpectation(
            _Behavior_IFacetName(), "expect_IFacet", "interfaces", expectedInterfaces_.length._toString()
        );
        expect_IFacet_facetInterfaces(subject, expectedInterfaces_);

        console.logBehaviorExpectation(
            _Behavior_IFacetName(), "expect_IFacet", "functions", expectedFunc_.length._toString()
        );
        expect_IFacet_facetFuncs(subject, expectedFunc_);

        console.logBehaviorExit(_Behavior_IFacetName(), "expect_IFacet");
    }
    // end::expect_IFacet(IFacet-string-bytes4[]-bytes4[])[]

    /* ------------------------------- facetName() ------------------------------ */

    // tag::funcSig_IFacet_facetName()[]
    /**
     * @notice Returns the IFacet.facetName() function signature for error messages and logging.
     * @return The function signature.
     * @custom:signature facetName()
     * @custom:selector 0x5b6f4d01
     */
    function funcSig_IFacet_facetName() public pure returns (string memory) {
        return "facetName()";
    }
    // end::funcSig_IFacet_facetName()[]

    // tag::errSuffix_IFacet_facetName()[]
    /**
     * @notice Returns a short suffix used in comparator error messages for facetName.
     * @return The error suffix.
     */
    function errSuffix_IFacet_facetName() public pure returns (string memory) {
        return "facet name";
    }
    // end::errSuffix_IFacet_facetName()[]

    // tag::areValid_IFacet_facetName(string-string-string)[]
    /**
     * @notice Validates facet name using string comparator (string subjectName overload).
     * @param subjectName The name/label of the contract being tested.
     * @param expected The expected facet name.
     * @param actual The actual facet name returned by subject.
     * @return valid True if the names match exactly.
     */
    function areValid_IFacet_facetName(string memory subjectName, string memory expected, string memory actual)
        public
        pure
        returns (bool valid)
    {
        console.logBehaviorEntry(_Behavior_IFacetName(), "areValid_IFacet_facetName");

        valid = StringComparator._compareStrings(
            expected, actual, _ifacet_errPrefix(funcSig_IFacet_facetName(), subjectName), errSuffix_IFacet_facetName()
        );

        console.logBehaviorValidation(_Behavior_IFacetName(), "areValid_IFacet_facetName", "facet name", valid);

        console.logBehaviorExit(_Behavior_IFacetName(), "areValid_IFacet_facetName");
        return valid;
    }
    // end::areValid_IFacet_facetName(string-string-string)[]

    // tag::areValid_IFacet_facetName(IFacet-string-string)[]
    /**
     * @notice Validates facet name (IFacet subject overload; resolves label internally).
     * @param subject The facet contract to test.
     * @param expected The expected facet name.
     * @param actual The actual facet name.
     * @return valid True if the names match exactly.
     */
    function areValid_IFacet_facetName(IFacet subject, string memory expected, string memory actual)
        public
        view
        returns (bool valid)
    {
        return areValid_IFacet_facetName(vm.getLabel(address(subject)), expected, actual);
    }
    // end::areValid_IFacet_facetName(IFacet-string-string)[]

    // tag::expect_IFacet_facetName(IFacet-string)[]
    /**
     * @notice Records the expected facet name for the subject (for subsequent hasValid_IFacet_facetName).
     * @param subject The facet contract to test.
     * @param expectedName The expected name value.
     */
    function expect_IFacet_facetName(IFacet subject, string memory expectedName) public {
        console.logBehaviorEntry(_Behavior_IFacetName(), "expect_IFacet_facetName");

        StringComparatorRepo._recExpectedString(address(subject), IFacet.facetName.selector, expectedName);

        console.logBehaviorExpectation(_Behavior_IFacetName(), "expect_IFacet_facetName", "facet name", expectedName);

        console.logBehaviorExit(_Behavior_IFacetName(), "expect_IFacet_facetName");
    }
    // end::expect_IFacet_facetName(IFacet-string)[]

    // tag::hasValid_IFacet_facetName(IFacet)[]
    /**
     * @notice Checks that the subject's current facetName() matches the previously expect'ed value.
     * @param subject The facet contract to test.
     * @return isValid_ True if current declaration is valid against expectation.
     */
    function hasValid_IFacet_facetName(IFacet subject) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IFacetName(), "hasValid_IFacet_facetName");

        isValid_ = areValid_IFacet_facetName(
            subject,
            StringComparatorRepo._recedExpectedString(address(subject), IFacet.facetName.selector),
            subject.facetName()
        );

        console.logBehaviorValidation(_Behavior_IFacetName(), "hasValid_IFacet_facetName", "facet name", isValid_);

        console.logBehaviorExit(_Behavior_IFacetName(), "hasValid_IFacet_facetName");
    }
    // end::hasValid_IFacet_facetName(IFacet)[]

    /* -------------------------- facetInterfaces() ------------------------- */

    // tag::funcSig_IFacet_facetInterfaces()[]
    /**
     * @notice Returns the IFacet.facetInterfaces() function signature.
     * @return The function signature.
     * @custom:signature facetInterfaces()
     * @custom:selector 0x2ea80826
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IFacet_facetInterfaces() public pure returns (string memory) {
        return "facetInterfaces()";
    }
    // end::funcSig_IFacet_facetInterfaces()[]

    // tag::errSuffix_IFacet_facetInterfaces()[]
    /**
     * @notice Returns a short suffix used in comparator error messages for facetInterfaces.
     * @return The error suffix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IFacet_facetInterfaces() public pure returns (string memory) {
        return "interface IDs";
    }
    // end::errSuffix_IFacet_facetInterfaces()[]

    // tag::areValid_IFacet_facetInterfaces(string-bytes4[]-bytes4[])[]

    /**
     * @notice Validates a facet's interface IDs against expectations (string subjectName overload).
     * @param subjectName The name/label of the contract being tested.
     * @param expected The expected interface IDs.
     * @param actual The actual interface IDs.
     * @return valid True if the interface IDs match expectations.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetInterfaces(
        string memory subjectName,
        bytes4[] memory expected,
        bytes4[] memory actual
    ) public returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IFacetName(), "areValid_IFacet_facetInterfaces");

        valid = Bytes4SetComparator._compare(
            expected,
            actual,
            _ifacet_errPrefix(funcSig_IFacet_facetInterfaces(), subjectName),
            errSuffix_IFacet_facetInterfaces()
        );

        console.logBehaviorValidation(_Behavior_IFacetName(), "areValid_IFacet_facetInterfaces", "interface IDs", valid);

        console.logBehaviorExit(_Behavior_IFacetName(), "areValid_IFacet_facetInterfaces");
        return valid;
    }
    // end::areValid_IFacet_facetInterfaces(string-bytes4[]-bytes4[])[]

    // tag::areValid_IFacet_facetInterfaces(IFacet-bytes4[]-bytes4[])[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetInterfaces(IFacet subject, bytes4[] memory expected, bytes4[] memory actual)
        public
        returns (bool valid)
    {
        return areValid_IFacet_facetInterfaces(vm.getLabel(address(subject)), expected, actual);
    }
    // end::areValid_IFacet_facetInterfaces(IFacet-bytes4[]-bytes4[])[]

    // tag::expect_IFacet_facetInterfaces(IFacet-bytes4[])[]

    /**
     * @notice Sets expectations for a facet's interface IDs (stores in Bytes4SetComparatorRepo).
     * @param subject The facet contract to test.
     * @param expectedInterfaces_ The expected interface IDs.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IFacet_facetInterfaces(IFacet subject, bytes4[] memory expectedInterfaces_) public {
        console.logBehaviorEntry(_Behavior_IFacetName(), "expect_IFacet_facetInterfaces");

        Bytes4SetComparatorRepo._recExpectedBytes4(
            address(subject), IFacet.facetInterfaces.selector, expectedInterfaces_
        );

        console.logBehaviorExpectation(
            _Behavior_IFacetName(),
            "expect_IFacet_facetInterfaces",
            "interface count",
            expectedInterfaces_.length._toString()
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "expect_IFacet_facetInterfaces");
    }
    // end::expect_IFacet_facetInterfaces(IFacet-bytes4[])[]

    // tag::hasValid_IFacet_facetInterfaces(IFacet)[]

    /**
     * @notice Validates that a facet's current interface IDs match the previously recorded expectation.
     * @param subject The facet contract to test.
     * @return isValid_ True if the interface IDs match expectations.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IFacet_facetInterfaces(IFacet subject) public returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IFacetName(), "hasValid_IFacet_facetInterfaces");

        isValid_ = areValid_IFacet_facetInterfaces(
            subject,
            Bytes4SetComparatorRepo._recedExpectedBytes4(address(subject), IFacet.facetInterfaces.selector)._values(),
            subject.facetInterfaces()
        );

        console.logBehaviorValidation(
            _Behavior_IFacetName(), "hasValid_IFacet_facetInterfaces", "interface configuration", isValid_
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "hasValid_IFacet_facetInterfaces");
    }
    // end::hasValid_IFacet_facetInterfaces(IFacet)[]

    /* ---------------------------- facetFuncs() ---------------------------- */

    // tag::funcSig_IFacet_facetFuncs()[]
    /**
     * @notice Returns the IFacet.facetFuncs() function signature.
     * @return The function signature.
     * @custom:signature facetFuncs()
     * @custom:selector 0x574a4cff
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IFacet_facetFuncs() public pure returns (string memory) {
        return "facetFuncs()";
    }
    // end::funcSig_IFacet_facetFuncs()[]

    // tag::errSuffix_IFacet_facetFuncs()[]
    /**
     * @notice Returns a short suffix used in comparator error messages for facetFuncs.
     * @return The error suffix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IFacet_facetFuncs() public pure returns (string memory) {
        return "function selectors";
    }
    // end::errSuffix_IFacet_facetFuncs()[]

    // tag::areValid_IFacet_facetFuncs(string-bytes4[]-bytes4[])[]

    /**
     * @notice Validates a facet's function selectors against expectations (string subjectName overload).
     * @param subjectName The name/label of the contract being tested.
     * @param expected The expected function selectors.
     * @param actual The actual function selectors.
     * @return valid True if the function selectors match expectations.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetFuncs(string memory subjectName, bytes4[] memory expected, bytes4[] memory actual)
        public
        returns (bool valid)
    {
        console.logBehaviorEntry(_Behavior_IFacetName(), "areValid_IFacet_facetFuncs");

        valid = Bytes4SetComparator._compare(
            expected, actual, _ifacet_errPrefix(funcSig_IFacet_facetFuncs(), subjectName), errSuffix_IFacet_facetFuncs()
        );

        console.logBehaviorValidation(_Behavior_IFacetName(), "areValid_IFacet_facetFuncs", "function selectors", valid);

        console.logBehaviorExit(_Behavior_IFacetName(), "areValid_IFacet_facetFuncs");
        return valid;
    }
    // end::areValid_IFacet_facetFuncs(string-bytes4[]-bytes4[])[]

    // tag::areValid_IFacet_facetFuncs(IFacet-bytes4[]-bytes4[])[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetFuncs(IFacet subject, bytes4[] memory expected, bytes4[] memory actual)
        public
        returns (bool valid)
    {
        return areValid_IFacet_facetFuncs(vm.getLabel(address(subject)), expected, actual);
    }
    // end::areValid_IFacet_facetFuncs(IFacet-bytes4[]-bytes4[])[]

    // tag::expect_IFacet_facetFuncs(IFacet-bytes4[])[]

    /**
     * @notice Sets expectations for a facet's function selectors (stores via Bytes4SetComparatorRepo).
     * @param subject The facet contract to test.
     * @param expectedFuncs_ The expected function selectors.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IFacet_facetFuncs(IFacet subject, bytes4[] memory expectedFuncs_) public {
        console.logBehaviorEntry(_Behavior_IFacetName(), "expect_IFacet_facetFuncs");

        Bytes4SetComparatorRepo._recExpectedBytes4(address(subject), IFacet.facetFuncs.selector, expectedFuncs_);

        console.logBehaviorExpectation(
            _Behavior_IFacetName(), "expect_IFacet_facetFuncs", "function count", expectedFuncs_.length._toString()
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "expect_IFacet_facetFuncs");
    }
    // end::expect_IFacet_facetFuncs(IFacet-bytes4[])[]

    // tag::hasValid_IFacet_facetFuncs(IFacet)[]

    /**
     * @notice Validates that a facet's current function selectors match the previously recorded expectation.
     * @param subject The facet contract to test.
     * @return isValid_ True if the function selectors match expectations.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IFacet_facetFuncs(IFacet subject) public returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IFacetName(), "hasValid_IFacet_facetFuncs");

        isValid_ = areValid_IFacet_facetFuncs(
            subject,
            Bytes4SetComparatorRepo._recedExpectedBytes4(address(subject), IFacet.facetFuncs.selector)._values(),
            subject.facetFuncs()
        );

        console.logBehaviorValidation(
            _Behavior_IFacetName(), "hasValid_IFacet_facetFuncs", "function configuration", isValid_
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "hasValid_IFacet_facetFuncs");
    }
    // end::hasValid_IFacet_facetFuncs(IFacet)[]

    /* -------------------------- facetMetadata() -------------------------- */

    // tag::funcSig_IFacet_facetMetadata()[]
    /**
     * @notice Returns the IFacet.facetMetadata() function signature.
     * @return The function signature.
     * @custom:signature facetMetadata()
     * @custom:selector 0xf10d7a75
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IFacet_facetMetadata() public pure returns (string memory) {
        return "facetMetadata()";
    }
    // end::funcSig_IFacet_facetMetadata()[]

    // tag::isValid_IFacet_facetMetadata_consistency(IFacet)[]

    /**
     * @notice Validates that facetMetadata() returns values consistent with individual getters.
     * @dev This ensures the aggregate function matches facetName(), facetInterfaces(), and facetFuncs() (LR-7 internal consistency).
     *      Used by TestBase_IFacet.test_IFacet_FacetMetadata_Consistency .
     * @param subject The facet contract to test.
     * @return valid True if all metadata components match their individual getter counterparts.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_IFacet_facetMetadata_consistency(IFacet subject) public returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IFacetName(), "isValid_IFacet_facetMetadata_consistency");

        // Get values from aggregate function
        (string memory metaName, bytes4[] memory metaInterfaces, bytes4[] memory metaFuncs) = subject.facetMetadata();

        // Get values from individual getters
        string memory individualName = subject.facetName();
        bytes4[] memory individualInterfaces = subject.facetInterfaces();
        bytes4[] memory individualFuncs = subject.facetFuncs();

        // Validate name consistency
        bool nameValid = areValid_IFacet_facetName(vm.getLabel(address(subject)), individualName, metaName);

        if (!nameValid) {
            console.logBehaviorError(
                _Behavior_IFacetName(),
                "isValid_IFacet_facetMetadata_consistency",
                "facetMetadata().name does not match",
                "facetName()"
            );
        }

        // Validate interfaces consistency
        bool interfacesValid = areValid_IFacet_facetInterfaces(subject, individualInterfaces, metaInterfaces);

        if (!interfacesValid) {
            console.logBehaviorError(
                _Behavior_IFacetName(),
                "isValid_IFacet_facetMetadata_consistency",
                "facetMetadata().interfaces does not match",
                "facetInterfaces()"
            );
        }

        // Validate functions consistency
        bool funcsValid = areValid_IFacet_facetFuncs(subject, individualFuncs, metaFuncs);

        if (!funcsValid) {
            console.logBehaviorError(
                _Behavior_IFacetName(),
                "isValid_IFacet_facetMetadata_consistency",
                "facetMetadata().functions does not match",
                "facetFuncs()"
            );
        }

        valid = nameValid && interfacesValid && funcsValid;

        console.logBehaviorValidation(
            _Behavior_IFacetName(), "isValid_IFacet_facetMetadata_consistency", "metadata consistency", valid
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "isValid_IFacet_facetMetadata_consistency");
        return valid;
    }
    // end::isValid_IFacet_facetMetadata_consistency(IFacet)[]

    // tag::areValid_IFacet_facetMetadata(IFacet-string-bytes4[]-bytes4[])[]

    /**
     * @notice Validates facetMetadata components against the individual getters (for declaration tests).
     * @dev Overload to support calls like areValid_IFacet_facetMetadata(subject, name, ifaces, funcs) extracted from metadata().
     * @param subject The facet contract to test.
     * @param metaName The name component from facetMetadata().
     * @param metaInterfaces The interfaces component from facetMetadata().
     * @param metaFuncs The funcs component from facetMetadata().
     * @return valid True if components are consistent with direct getters.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetMetadata(
        IFacet subject,
        string memory metaName,
        bytes4[] memory metaInterfaces,
        bytes4[] memory metaFuncs
    ) public returns (bool valid) {
        console.logBehaviorEntry(_Behavior_IFacetName(), "areValid_IFacet_facetMetadata");

        string memory label = vm.getLabel(address(subject));
        bool nameValid = areValid_IFacet_facetName(label, subject.facetName(), metaName);
        bool ifacesValid = areValid_IFacet_facetInterfaces(subject, subject.facetInterfaces(), metaInterfaces);
        bool funcsValid = areValid_IFacet_facetFuncs(subject, subject.facetFuncs(), metaFuncs);

        valid = nameValid && ifacesValid && funcsValid;

        console.logBehaviorValidation(
            _Behavior_IFacetName(), "areValid_IFacet_facetMetadata", "facetMetadata components", valid
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "areValid_IFacet_facetMetadata");
        return valid;
    }
    // end::areValid_IFacet_facetMetadata(IFacet-string-bytes4[]-bytes4[])[]

// end::Behavior_IFacet[]
}
