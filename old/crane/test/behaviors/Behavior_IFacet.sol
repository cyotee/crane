// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {Behavior} from "contracts/crane/test/behaviors/Behavior.sol";

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
import {Bytes4SetComparator} from "contracts/crane/test/comparators/sets/Bytes4SetComparator.sol";
import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";

import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

/**
 * @title Behavior_IFacet
 * @notice Behavior contract for testing IFacet implementations
 * @dev Validates that contracts correctly implement the IFacet interface
 *      by checking interface IDs and function selectors. This contract is crucial
 *      for ensuring diamond facets are correctly configured and exposed.
 */
contract Behavior_IFacet is Behavior, Bytes4SetComparator {
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

    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IFacetName() internal pure returns (string memory) {
        return type(Behavior_IFacet).name;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefixFunc(string memory testedFuncSig) internal view virtual returns (string memory) {
        return _errPrefixFunc(_Behavior_IFacetName(), testedFuncSig);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        view
        virtual
        returns (string memory)
    {
        return string.concat(_ifacet_errPrefixFunc(testedFuncSig), subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ifacet_errPrefix(string memory testedFuncSig, address subject)
        internal
        view
        virtual
        returns (string memory)
    {
        return _ifacet_errPrefix(testedFuncSig, vm.getLabel(subject));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IFacet(IFacet subject, bytes4[] memory expectedInterfaces_, bytes4[] memory expectedFunc_) public {
        console.logBehaviorEntry(_Behavior_IFacetName(), "expect_IFacet");

        console.logBehaviorExpectation(
            _Behavior_IFacetName(), "expect_IFacet", "interfaces", expectedInterfaces_.length.toString()
        );
        expect_IFacet_facetInterfaces(subject, expectedInterfaces_);

        console.logBehaviorExpectation(
            _Behavior_IFacetName(), "expect_IFacet", "functions", expectedFunc_.length.toString()
        );
        expect_IFacet_facetFuncs(subject, expectedFunc_);

        console.logBehaviorExit(_Behavior_IFacetName(), "expect_IFacet");
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

        valid = _compare(
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

        _recExpectedBytes4(address(subject), IFacet.facetInterfaces.selector, expectedInterfaces_);

        console.logBehaviorExpectation(
            _Behavior_IFacetName(),
            "expect_IFacet_facetInterfaces",
            "interface count",
            expectedInterfaces_.length.toString()
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
            _recedExpectedBytes4(address(subject), IFacet.facetInterfaces.selector)._values(),
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

        valid = _compare(
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

        _recExpectedBytes4(address(subject), IFacet.facetFuncs.selector, expectedFuncs_);

        console.logBehaviorExpectation(
            _Behavior_IFacetName(), "expect_IFacet_facetFuncs", "function count", expectedFuncs_.length.toString()
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
            subject, _recedExpectedBytes4(address(subject), IFacet.facetFuncs.selector)._values(), subject.facetFuncs()
        );

        console.logBehaviorValidation(
            _Behavior_IFacetName(), "hasValid_IFacet_facetFuncs", "function configuration", isValid_
        );

        console.logBehaviorExit(_Behavior_IFacetName(), "hasValid_IFacet_facetFuncs");
    }
}
