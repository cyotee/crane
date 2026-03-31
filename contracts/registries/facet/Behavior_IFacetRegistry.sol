// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IFacetRegistry} from "@crane/contracts/interfaces/IFacetRegistry.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {
    AddressSetComparatorRepo,
    AddressSetComparator
} from "@crane/contracts/test/comparators/AddressSetComparator.sol";
import {StringSetComparatorRepo, StringSetComparator} from "@crane/contracts/test/comparators/StringSetComparator.sol";

library Behavior_IFacetRegistry {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    function _name() internal pure returns (string memory) {
        return type(Behavior_IFacetRegistry).name;
    }

    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_name(), testedFuncSig);
    }

    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, string memory subjectLabel) internal pure returns (string memory) {
        return string.concat(_errPrefixFunc(testedFuncSig), subjectLabel);
    }

    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subject The address of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _errPrefix(testedFuncSig, vm.getLabel(subject));
    }

    /* -------------------------------------------------------------------------- */
    /*                                 allFacets()                                */
    /* -------------------------------------------------------------------------- */

    function funcSig_allFacets() public pure returns (string memory) {
        return "allFacets()";
    }

    function errSuffix_allFacets() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_allFacets(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_allFacets(), subjectLabel);
    }

    function errBody_allFacets() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IFacetRegistry_allFacets(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_allFacets(), subjectLabel),
            errSuffix_allFacets()
        );
    }

    function areValid_IFacetRegistry_allFacets(
        IFacetRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        // declareAddr(address(subject));
        return areValid_IFacetRegistry_allFacets(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IFacetRegistry_allFacets(IFacetRegistry subject, address[] memory expectedFacetAddresses_)
        internal
    {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), IFacetRegistry.allFacets.selector, expectedFacetAddresses_
        );
    }

    function expect_IFacetRegistry_allFacets(IFacetRegistry subject, address expectedFacetAddress_) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), IFacetRegistry.allFacets.selector, expectedFacetAddress_
        );
    }

    function hasValid_IFacetRegistry_allFacets(IFacetRegistry subject) internal returns (bool isValid_) {
        return areValid_IFacetRegistry_allFacets(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(address(subject), IFacetRegistry.allFacets.selector)._values(),
            // bytes4[] memory actual
            subject.allFacets()
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                            facetsOfName(string)                            */
    /* -------------------------------------------------------------------------- */

    function funcSig_facetsOfName() public pure returns (string memory) {
        return "facetsOfName()";
    }

    function errSuffix_facetsOfName() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_facetsOfName(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_facetsOfName(), subjectLabel);
    }

    function errBody_facetsOfName() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IFacetRegistry_facetsOfName(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_facetsOfName(), subjectLabel),
            errSuffix_facetsOfName()
        );
    }

    function areValid_IFacetRegistry_facetsOfName(
        IFacetRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return areValid_IFacetRegistry_facetsOfName(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IFacetRegistry_facetsOfName(
        IFacetRegistry subject,
        string memory key0,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), abi.encode(IFacetRegistry.facetsOfName.selector, key0)._hash(), expectedFacetAddresses_
        );
    }

    function expect_IFacetRegistry_facetsOfName(
        IFacetRegistry subject,
        string memory key0,
        address expectedFacetAddress_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), abi.encode(IFacetRegistry.facetsOfName.selector, key0)._hash(), expectedFacetAddress_
        );
    }

    function hasValid_IFacetRegistry_facetsOfName(IFacetRegistry subject, string memory key0)
        internal
        returns (bool isValid_)
    {
        return areValid_IFacetRegistry_facetsOfName(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject), abi.encode(IFacetRegistry.facetsOfName.selector, key0)._hash()
                )._values(),
            // bytes4[] memory actual
            subject.facetsOfName(key0)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          facetsOfInterface(bytes4)                         */
    /* -------------------------------------------------------------------------- */

    function funcSig_facetsOfInterface() public pure returns (string memory) {
        return "facetsOfInterface(bytes4)";
    }

    function errSuffix_facetsOfInterface() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_facetsOfInterface(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_facetsOfInterface(), subjectLabel);
    }

    function errBody_facetsOfInterface() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IFacetRegistry_facetsOfInterface(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_facetsOfInterface(), subjectLabel),
            errSuffix_facetsOfInterface()
        );
    }

    function areValid_IFacetRegistry_facetsOfInterface(
        IFacetRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return areValid_IFacetRegistry_facetsOfInterface(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IFacetRegistry_facetsOfInterface(
        IFacetRegistry subject,
        bytes4 key0,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IFacetRegistry.facetsOfInterface.selector, key0)._hash(),
            expectedFacetAddresses_
        );
    }

    function expect_IFacetRegistry_facetsOfInterface(IFacetRegistry subject, bytes4 key0, address expectedFacetAddress_)
        internal
    {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), abi.encode(IFacetRegistry.facetsOfInterface.selector, key0)._hash(), expectedFacetAddress_
        );
    }

    function hasValid_IFacetRegistry_facetsOfInterface(IFacetRegistry subject, bytes4 key0)
        internal
        returns (bool isValid_)
    {
        return areValid_IFacetRegistry_facetsOfInterface(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject), abi.encode(IFacetRegistry.facetsOfInterface.selector, key0)._hash()
                )._values(),
            // bytes4[] memory actual
            subject.facetsOfInterface(key0)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          facetsOfFunction(bytes4)                          */
    /* -------------------------------------------------------------------------- */

    function funcSig_facetsOfFunction() public pure returns (string memory) {
        return "facetsOfFunction(bytes4)";
    }

    function errSuffix_facetsOfFunction() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_facetsOfFunction(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_facetsOfFunction(), subjectLabel);
    }

    function errBody_facetsOfFunction() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IFacetRegistry_facetsOfFunction(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_facetsOfFunction(), subjectLabel),
            errSuffix_facetsOfFunction()
        );
    }

    function areValid_IFacetRegistry_facetsOfFunction(
        IFacetRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return areValid_IFacetRegistry_facetsOfFunction(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IFacetRegistry_facetsOfFunction(
        IFacetRegistry subject,
        bytes4 key0,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IFacetRegistry.facetsOfFunction.selector, key0)._hash(),
            expectedFacetAddresses_
        );
    }

    function expect_IFacetRegistry_facetsOfFunction(IFacetRegistry subject, bytes4 key0, address expectedFacetAddress_)
        internal
    {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), abi.encode(IFacetRegistry.facetsOfFunction.selector, key0)._hash(), expectedFacetAddress_
        );
    }

    function hasValid_IFacetRegistry_facetsOfFunction(IFacetRegistry subject, bytes4 key0)
        internal
        returns (bool isValid_)
    {
        return areValid_IFacetRegistry_facetsOfFunction(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject), abi.encode(IFacetRegistry.facetsOfFunction.selector, key0)._hash()
                )._values(),
            // bytes4[] memory actual
            subject.facetsOfFunction(key0)
        );
    }
}
