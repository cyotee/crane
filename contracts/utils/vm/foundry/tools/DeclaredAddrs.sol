// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    AddressSet,
    AddressSetRepo
} from "../../../collections/sets/AddressSetRepo.sol";

import {FoundryVM} from "../FoundryVM.sol";

interface IDeclaredAddrs
{

    function declaredAddrs()
    external view returns(address[] memory);

    function isDeclared(
        address subject
    ) external view returns(bool);

    function declareAddr(
        address dec,
        string memory label
    ) external returns(bool);

    function declareAddr(
        address dec
    ) external returns(bool);

}

contract DeclaredAddrs
is
FoundryVM,
IDeclaredAddrs
{

    using AddressSetRepo for AddressSet;

    AddressSet internal _declaredAddrs;

    // TODO Add multi-chain support.
    // mapping(uint256 chainId => mapping(bytes32 label => address subject)) internal _declaredAddrsOfChain;

    function declaredAddrs()
    public view returns(address[] memory) {
        return _declaredAddrs._values();
    }

    function isDeclared(
        address subject
    ) public view returns(bool) {
        return _declaredAddrs._contains(subject);
    }

    function declareAddr(
        address dec
    ) public returns(bool) {
        _declaredAddrs._add(dec);
        return true;
    }

    function declareAddr(
        address dec,
        string memory label
    ) public returns(bool) {
        declareAddr(dec);
        vm.label(
            dec,
            label
        );
        return true;
    }

}