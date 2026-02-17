// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/contracts/utils/collections/sets/StringSetRepo.sol";
import {IFacet} from "@crane/contracts/factories/diamondPkg/IFacet.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/interfaces/IDiamondFactoryPackageRegistry.sol";
import {
    Behavior_IDiamondFactoryPackageRegistry
} from "@crane/contracts/registries/package/Behavior_IDiamondFactoryPackageRegistry.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
// import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";

contract Handler_IDiamondFactoryPackageRegistry {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using StringSetRepo for StringSet;

    AddressSet _subjects;
    mapping(address subject => StringSet names) _namesOfSubject;
    mapping(address subject => Bytes4Set interfaces) _interfacesOfSubject;
    mapping(address subject => AddressSet facets) _facetsOfSubject;

    function recInvariant_IDiamondFactoryPackage(IDiamondFactoryPackageRegistry subject, IDiamondFactoryPackage package)
        public
    {
        recInvariant_allPackages(subject);
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = package.packageMetadata();
        recInvariant_packagesByName(subject, name);
        recInvariant_packagesByInterface(subject, interfaces);
        recInvariant_packagesByFacet(subject, facets);
    }

    function recInvariant_allPackages(IDiamondFactoryPackageRegistry subject) public {
        _subjects._add(address(subject));
        Behavior_IDiamondFactoryPackageRegistry.expect_IDiamondFactoryPackageRegistry_allPackages(
            subject, subject.allPackages()
        );
    }

    function recInvariant_packagesByName(IDiamondFactoryPackageRegistry subject, string memory key0) public {
        _subjects._add(address(subject));
        _namesOfSubject[address(subject)]._add(key0);
        Behavior_IDiamondFactoryPackageRegistry.expect_IDiamondFactoryPackageRegistry_packagesByName(
            subject, key0, subject.packagesByName(key0)
        );
    }

    function recInvariant_packagesByInterface(IDiamondFactoryPackageRegistry subject, bytes4 key0) public {
        _subjects._add(address(subject));
        _interfacesOfSubject[address(subject)]._add(key0);
        Behavior_IDiamondFactoryPackageRegistry.expect_IDiamondFactoryPackageRegistry_packagesByInterface(
            subject, key0, subject.packagesByInterface(key0)
        );
    }

    function recInvariant_packagesByInterface(IDiamondFactoryPackageRegistry subject, bytes4[] memory key0) public {
        for (uint256 cursor = 0; cursor < key0.length; cursor++) {
            recInvariant_packagesByInterface(subject, key0[cursor]);
        }
    }

    function recInvariant_packagesByFacet(IDiamondFactoryPackageRegistry subject, address key0) public {
        _subjects._add(address(subject));
        _facetsOfSubject[address(subject)]._add(key0);
        Behavior_IDiamondFactoryPackageRegistry.expect_IDiamondFactoryPackageRegistry_packagesByFacet(
            subject, IFacet(key0), subject.packagesByFacet(IFacet(key0))
        );
    }

    function recInvariant_packagesByFacet(IDiamondFactoryPackageRegistry subject, address[] memory key0) public {
        for (uint256 cursor = 0; cursor < key0.length; cursor++) {
            recInvariant_packagesByFacet(subject, key0[cursor]);
        }
    }

    function assert_IDiamondFactoryPackageRegistry() public {
        for (uint256 cursor = 0; cursor < _subjects._length(); cursor++) {
            assert_IDiamondFactoryPackageRegistry(IDiamondFactoryPackageRegistry(_subjects._index(cursor)));
        }
    }

    function assert_IDiamondFactoryPackageRegistry(IDiamondFactoryPackageRegistry subject) public {
        assert_allPackages(subject);
        assert_packagesByName(subject);
        assert_packagesByInterface(subject);
        assert_packagesByFacet(subject);
    }

    function assert_allPackages(IDiamondFactoryPackageRegistry subject) public {
        assert(Behavior_IDiamondFactoryPackageRegistry.hasValid_IDiamondFactoryPackageRegistry_allPackages(subject));
    }

    function assert_packagesByName(IDiamondFactoryPackageRegistry subject) public {
        for (uint256 cursor; cursor < _namesOfSubject[address(subject)]._length(); cursor++) {
            assert(
                Behavior_IDiamondFactoryPackageRegistry.hasValid_IDiamondFactoryPackageRegistry_packagesByName(
                    subject, _namesOfSubject[address(subject)]._index(cursor)
                )
            );
        }
    }

    function assert_packagesByInterface(IDiamondFactoryPackageRegistry subject) public {
        for (uint256 cursor; cursor < _interfacesOfSubject[address(subject)]._length(); cursor++) {
            assert(
                Behavior_IDiamondFactoryPackageRegistry.hasValid_IDiamondFactoryPackageRegistry_packagesByInterface(
                    subject, _interfacesOfSubject[address(subject)]._index(cursor)
                )
            );
        }
    }

    function assert_packagesByFacet(IDiamondFactoryPackageRegistry subject) public {
        for (uint256 cursor; cursor < _facetsOfSubject[address(subject)]._length(); cursor++) {
            assert(
                Behavior_IDiamondFactoryPackageRegistry.hasValid_IDiamondFactoryPackageRegistry_packagesByFacet(
                    subject, IFacet(_facetsOfSubject[address(subject)]._index(cursor))
                )
            );
        }
    }
}
