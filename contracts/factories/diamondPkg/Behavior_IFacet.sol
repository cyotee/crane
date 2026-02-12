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

library Behavior_IFacet {
    using Bytes4SetRepo for Bytes4Set;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IFacetName() internal pure returns (string memory) {
        return type(Behavior_IFacet).name;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_Behavior_IFacetName(), testedFuncSig);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_ifacet_errPrefixFunc(testedFuncSig), subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _ifacet_errPrefix(testedFuncSig, vm.getLabel(subject));
    }

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

    /* ------------------------------- facetName() ------------------------------ */

    function funcSig_IFacet_facetName() public pure returns (string memory) {
        return "facetName()";
    }

    function errSuffix_IFacet_facetName() public pure returns (string memory) {
        return "facet name";
    }

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

    function areValid_IFacet_facetName(IFacet subject, string memory expected, string memory actual)
        public
        view
        returns (bool valid)
    {
        return areValid_IFacet_facetName(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IFacet_facetName(IFacet subject, string memory expectedName) public {
        console.logBehaviorEntry(_Behavior_IFacetName(), "expect_IFacet_facetName");

        StringComparatorRepo._recExpectedString(address(subject), IFacet.facetName.selector, expectedName);

        console.logBehaviorExpectation(_Behavior_IFacetName(), "expect_IFacet_facetName", "facet name", expectedName);

        console.logBehaviorExit(_Behavior_IFacetName(), "expect_IFacet_facetName");
    }

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

    /* -------------------------- facetInterfaces() ------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IFacet_facetInterfaces() public pure returns (string memory) {
        return "facetInterfaces()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IFacet_facetInterfaces() public pure returns (string memory) {
        return "interface IDs";
    }

    /**
     * @notice Validates a facet's interface IDs against expectations
     * @param subjectName The name/label of the contract being tested
     * @param expected The expected interface IDs
     * @param actual The actual interface IDs
     * @return valid True if the interface IDs match expectations
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

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetInterfaces(IFacet subject, bytes4[] memory expected, bytes4[] memory actual)
        public
        returns (bool valid)
    {
        return areValid_IFacet_facetInterfaces(vm.getLabel(address(subject)), expected, actual);
    }

    /**
     * @notice Sets expectations for a facet's interface IDs
     * @param subject The facet contract to test
     * @param expectedInterfaces_ The expected interface IDs
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

    /**
     * @notice Validates that a facet's current interface IDs match expectations
     * @param subject The facet contract to test
     * @return isValid_ True if the interface IDs match expectations
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

    /* ---------------------------- facetFuncs() ---------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IFacet_facetFuncs() public pure returns (string memory) {
        return "facetFuncs()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_IFacet_facetFuncs() public pure returns (string memory) {
        return "function selectors";
    }

    /**
     * @notice Validates a facet's function selectors against expectations
     * @param subjectName The name/label of the contract being tested
     * @param expected The expected function selectors
     * @param actual The actual function selectors
     * @return valid True if the function selectors match expectations
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

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_IFacet_facetFuncs(IFacet subject, bytes4[] memory expected, bytes4[] memory actual)
        public
        returns (bool valid)
    {
        return areValid_IFacet_facetFuncs(vm.getLabel(address(subject)), expected, actual);
    }

    /**
     * @notice Sets expectations for a facet's function selectors
     * @param subject The facet contract to test
     * @param expectedFuncs_ The expected function selectors
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

    /**
     * @notice Validates that a facet's current function selectors match expectations
     * @param subject The facet contract to test
     * @return isValid_ True if the function selectors match expectations
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

    /* -------------------------- facetMetadata() -------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IFacet_facetMetadata() public pure returns (string memory) {
        return "facetMetadata()";
    }

    /**
     * @notice Validates that facetMetadata() returns values consistent with individual getters
     * @dev This ensures the aggregate function matches facetName(), facetInterfaces(), and facetFuncs()
     * @param subject The facet contract to test
     * @return valid True if all metadata components match their individual getter counterparts
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
        bool nameValid = areValid_IFacet_facetName(
            vm.getLabel(address(subject)),
            individualName,
            metaName
        );

        if (!nameValid) {
            console.logBehaviorError(
                _Behavior_IFacetName(),
                "isValid_IFacet_facetMetadata_consistency",
                "facetMetadata().name does not match",
                "facetName()"
            );
        }

        // Validate interfaces consistency
        bool interfacesValid = areValid_IFacet_facetInterfaces(
            subject,
            individualInterfaces,
            metaInterfaces
        );

        if (!interfacesValid) {
            console.logBehaviorError(
                _Behavior_IFacetName(),
                "isValid_IFacet_facetMetadata_consistency",
                "facetMetadata().interfaces does not match",
                "facetInterfaces()"
            );
        }

        // Validate functions consistency
        bool funcsValid = areValid_IFacet_facetFuncs(
            subject,
            individualFuncs,
            metaFuncs
        );

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
            _Behavior_IFacetName(),
            "isValid_IFacet_facetMetadata_consistency",
            "metadata consistency",
            valid
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "isValid_IFacet_facetMetadata_consistency");
        return valid;
    }
}
