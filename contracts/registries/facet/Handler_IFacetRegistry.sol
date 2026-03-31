// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/contracts/utils/collections/sets/StringSetRepo.sol";
import {IFacet} from "@crane/contracts/factories/diamondPkg/IFacet.sol";
import {IFacetRegistry} from "@crane/contracts/interfaces/IFacetRegistry.sol";
import {Behavior_IFacetRegistry} from "@crane/contracts/registries/facet/Behavior_IFacetRegistry.sol";

contract Handler_IFacetRegistry {
    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    using StringSetRepo for StringSet;

    AddressSet _subjects;
    mapping(address subject => StringSet names) _namesOfSubject;
    mapping(address subject => Bytes4Set interfaces) _interfacesOfSubject;
    mapping(address subject => Bytes4Set funcs) _funcsOfSubject;

    function recInvariant_IFacet(IFacetRegistry subject, IFacet facet) public {
        recInvariant_allFacets(subject);
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        recInvariant_facetsOfName(subject, name);
        recInvariant_facetsOfInterface(subject, interfaces);
        recInvariant_facetsOfFunction(subject, functions);
    }

    function recInvariant_allFacets(IFacetRegistry subject) public {
        _subjects._add(address(subject));
        Behavior_IFacetRegistry.expect_IFacetRegistry_allFacets(subject, subject.allFacets());
    }

    function recInvariant_facetsOfName(IFacetRegistry subject, string memory key0) public {
        _subjects._add(address(subject));
        _namesOfSubject[address(subject)]._add(key0);
        Behavior_IFacetRegistry.expect_IFacetRegistry_facetsOfName(subject, key0, subject.facetsOfName(key0));
    }

    function recInvariant_facetsOfInterface(IFacetRegistry subject, bytes4 key0) public {
        _subjects._add(address(subject));
        _interfacesOfSubject[address(subject)]._add(key0);
        Behavior_IFacetRegistry.expect_IFacetRegistry_facetsOfInterface(subject, key0, subject.facetsOfInterface(key0));
    }

    function recInvariant_facetsOfInterface(IFacetRegistry subject, bytes4[] memory key0) public {
        for (uint256 cursor = 0; cursor < key0.length; cursor++) {
            recInvariant_facetsOfInterface(subject, key0[cursor]);
        }
    }

    function recInvariant_facetsOfFunction(IFacetRegistry subject, bytes4 key0) public {
        _subjects._add(address(subject));
        _funcsOfSubject[address(subject)]._add(key0);
        Behavior_IFacetRegistry.expect_IFacetRegistry_facetsOfFunction(subject, key0, subject.facetsOfFunction(key0));
    }

    function recInvariant_facetsOfFunction(IFacetRegistry subject, bytes4[] memory key0) public {
        for (uint256 cursor = 0; cursor < key0.length; cursor++) {
            recInvariant_facetsOfFunction(subject, key0[cursor]);
        }
    }

    function assert_IFacetRegistry() public {
        for (uint256 cursor = 0; cursor < _subjects._length(); cursor++) {
            assert_IFacetRegistry(IFacetRegistry(_subjects._index(cursor)));
        }
    }

    function assert_IFacetRegistry(IFacetRegistry subject) public {
        assert_allFacets(subject);
        assert_facetsOfName(subject);
        assert_facetsOfInterface(subject);
        assert_facetsOfFunction(subject);
    }

    function assert_allFacets(IFacetRegistry subject) public {
        assert(Behavior_IFacetRegistry.hasValid_IFacetRegistry_allFacets(subject));
    }

    function assert_facetsOfName(IFacetRegistry subject) public {
        for (uint256 cursor; cursor < _namesOfSubject[address(subject)]._length(); cursor++) {
            assert(
                Behavior_IFacetRegistry.hasValid_IFacetRegistry_facetsOfName(
                    subject, _namesOfSubject[address(subject)]._index(cursor)
                )
            );
        }
    }

    function assert_facetsOfInterface(IFacetRegistry subject) public {
        for (uint256 cursor; cursor < _interfacesOfSubject[address(subject)]._length(); cursor++) {
            assert(
                Behavior_IFacetRegistry.hasValid_IFacetRegistry_facetsOfInterface(
                    subject, _interfacesOfSubject[address(subject)]._index(cursor)
                )
            );
        }
    }

    function assert_facetsOfFunction(IFacetRegistry subject) public {
        for (uint256 cursor; cursor < _funcsOfSubject[address(subject)]._length(); cursor++) {
            assert(
                Behavior_IFacetRegistry.hasValid_IFacetRegistry_facetsOfFunction(
                    subject, _funcsOfSubject[address(subject)]._index(cursor)
                )
            );
        }
    }
}
