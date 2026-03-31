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
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {
    AddressSetComparatorRepo,
    AddressSetComparator
} from "@crane/contracts/test/comparators/AddressSetComparator.sol";
import {StringSetComparatorRepo, StringSetComparator} from "@crane/contracts/test/comparators/StringSetComparator.sol";

library Behavior_IDiamondFactoryPackageRegistry {
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
        return type(Behavior_IDiamondFactoryPackageRegistry).name;
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
    /*                                 allPackages()                                */
    /* -------------------------------------------------------------------------- */

    function funcSig_allPackages() public pure returns (string memory) {
        return "allPackages()";
    }

    function errSuffix_allPackages() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_allPackages(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_allPackages(), subjectLabel);
    }

    function errBody_allPackages() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IDiamondFactoryPackageRegistry_allPackages(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_allPackages(), subjectLabel),
            errSuffix_allPackages()
        );
    }

    function areValid_IDiamondFactoryPackageRegistry_allPackages(
        IDiamondFactoryPackageRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        // declareAddr(address(subject));
        return areValid_IDiamondFactoryPackageRegistry_allPackages(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IDiamondFactoryPackageRegistry_allPackages(
        IDiamondFactoryPackageRegistry subject,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), IDiamondFactoryPackageRegistry.allPackages.selector, expectedFacetAddresses_
        );
    }

    function expect_IDiamondFactoryPackageRegistry_allPackages(
        IDiamondFactoryPackageRegistry subject,
        address expectedFacetAddress_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject), IDiamondFactoryPackageRegistry.allPackages.selector, expectedFacetAddress_
        );
    }

    function hasValid_IDiamondFactoryPackageRegistry_allPackages(IDiamondFactoryPackageRegistry subject)
        internal
        returns (bool isValid_)
    {
        return areValid_IDiamondFactoryPackageRegistry_allPackages(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject), IDiamondFactoryPackageRegistry.allPackages.selector
                )._values(),
            // bytes4[] memory actual
            subject.allPackages()
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                            packagesByName(string)                            */
    /* -------------------------------------------------------------------------- */

    function funcSig_packagesByName() public pure returns (string memory) {
        return "packagesByName()";
    }

    function errSuffix_packagesByName() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_packagesByName(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_packagesByName(), subjectLabel);
    }

    function errBody_packagesByName() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IDiamondFactoryPackageRegistry_packagesByName(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_packagesByName(), subjectLabel),
            errSuffix_packagesByName()
        );
    }

    function areValid_IDiamondFactoryPackageRegistry_packagesByName(
        IDiamondFactoryPackageRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return areValid_IDiamondFactoryPackageRegistry_packagesByName(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IDiamondFactoryPackageRegistry_packagesByName(
        IDiamondFactoryPackageRegistry subject,
        string memory key0,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IDiamondFactoryPackageRegistry.packagesByName.selector, key0)._hash(),
            expectedFacetAddresses_
        );
    }

    function expect_IDiamondFactoryPackageRegistry_packagesByName(
        IDiamondFactoryPackageRegistry subject,
        string memory key0,
        address expectedFacetAddress_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IDiamondFactoryPackageRegistry.packagesByName.selector, key0)._hash(),
            expectedFacetAddress_
        );
    }

    function hasValid_IDiamondFactoryPackageRegistry_packagesByName(
        IDiamondFactoryPackageRegistry subject,
        string memory key0
    ) internal returns (bool isValid_) {
        return areValid_IDiamondFactoryPackageRegistry_packagesByName(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject), abi.encode(IDiamondFactoryPackageRegistry.packagesByName.selector, key0)._hash()
                )._values(),
            // bytes4[] memory actual
            subject.packagesByName(key0)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          packagesByInterface(bytes4)                         */
    /* -------------------------------------------------------------------------- */

    function funcSig_packagesByInterface() public pure returns (string memory) {
        return "packagesByInterface(bytes4)";
    }

    function errSuffix_packagesByInterface() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_packagesByInterface(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_packagesByInterface(), subjectLabel);
    }

    function errBody_packagesByInterface() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IDiamondFactoryPackageRegistry_packagesByInterface(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_packagesByInterface(), subjectLabel),
            errSuffix_packagesByInterface()
        );
    }

    function areValid_IDiamondFactoryPackageRegistry_packagesByInterface(
        IDiamondFactoryPackageRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return areValid_IDiamondFactoryPackageRegistry_packagesByInterface(
            vm.getLabel(address(subject)), expected, actual
        );
    }

    function expect_IDiamondFactoryPackageRegistry_packagesByInterface(
        IDiamondFactoryPackageRegistry subject,
        bytes4 key0,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IDiamondFactoryPackageRegistry.packagesByInterface.selector, key0)._hash(),
            expectedFacetAddresses_
        );
    }

    function expect_IDiamondFactoryPackageRegistry_packagesByInterface(
        IDiamondFactoryPackageRegistry subject,
        bytes4 key0,
        address expectedFacetAddress_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IDiamondFactoryPackageRegistry.packagesByInterface.selector, key0)._hash(),
            expectedFacetAddress_
        );
    }

    function hasValid_IDiamondFactoryPackageRegistry_packagesByInterface(
        IDiamondFactoryPackageRegistry subject,
        bytes4 key0
    ) internal returns (bool isValid_) {
        return areValid_IDiamondFactoryPackageRegistry_packagesByInterface(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject),
                    abi.encode(IDiamondFactoryPackageRegistry.packagesByInterface.selector, key0)._hash()
                )._values(),
            // bytes4[] memory actual
            subject.packagesByInterface(key0)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          packagesByFacet(IFacet)                          */
    /* -------------------------------------------------------------------------- */

    function funcSig_packagesByFacet() public pure returns (string memory) {
        return "packagesByFacet(bytes4)";
    }

    function errSuffix_packagesByFacet() internal pure returns (string memory) {
        return "facet addresses";
    }

    function _errPrefix_packagesByFacet(string memory subjectLabel) internal pure returns (string memory) {
        return _errPrefix(funcSig_packagesByFacet(), subjectLabel);
    }

    function errBody_packagesByFacet() public pure returns (string memory) {
        return "Facet registry facet set mismatch";
    }

    function areValid_IDiamondFactoryPackageRegistry_packagesByFacet(
        string memory subjectLabel,
        address[] memory expected,
        address[] memory actual
    ) public returns (bool result) {
        return AddressSetComparator._compare(
            expected,
            actual,
            BehaviorUtils._errPrefix(_name(), funcSig_packagesByFacet(), subjectLabel),
            errSuffix_packagesByFacet()
        );
    }

    function areValid_IDiamondFactoryPackageRegistry_packagesByFacet(
        IDiamondFactoryPackageRegistry subject,
        address[] memory expected,
        address[] memory actual
    ) internal returns (bool valid) {
        return areValid_IDiamondFactoryPackageRegistry_packagesByFacet(vm.getLabel(address(subject)), expected, actual);
    }

    function expect_IDiamondFactoryPackageRegistry_packagesByFacet(
        IDiamondFactoryPackageRegistry subject,
        IFacet key0,
        address[] memory expectedFacetAddresses_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IDiamondFactoryPackageRegistry.packagesByFacet.selector, key0)._hash(),
            expectedFacetAddresses_
        );
    }

    function expect_IDiamondFactoryPackageRegistry_packagesByFacet(
        IDiamondFactoryPackageRegistry subject,
        IFacet key0,
        address expectedFacetAddress_
    ) internal {
        AddressSetComparatorRepo._recExpectedAddrs(
            address(subject),
            abi.encode(IDiamondFactoryPackageRegistry.packagesByFacet.selector, key0)._hash(),
            expectedFacetAddress_
        );
    }

    function hasValid_IDiamondFactoryPackageRegistry_packagesByFacet(
        IDiamondFactoryPackageRegistry subject,
        IFacet key0
    ) internal returns (bool isValid_) {
        return areValid_IDiamondFactoryPackageRegistry_packagesByFacet(
            // address subject,
            subject,
            // address[] memory expected,
            AddressSetComparatorRepo._recedExpectedAddrs(
                    address(subject), abi.encode(IDiamondFactoryPackageRegistry.packagesByFacet.selector, key0)._hash()
                )._values(),
            // bytes4[] memory actual
            subject.packagesByFacet(key0)
        );
    }
}
