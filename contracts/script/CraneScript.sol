// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {terminal as term} from "../utils/vm/foundry/tools/terminal/terminal.sol";

import {
    AddressSet,
    AddressSetRepo
} from "../utils/collections/sets/AddressSetRepo.sol";
import {
    FoundryVM
} from "../utils/vm/foundry/FoundryVM.sol";
import {
    Fixture
} from "../fixtures/Fixture.sol";
import {
    CamelotV2Fixture
} from "../protocols/dexes/camelot/v2/fixtures/CamelotV2Fixture.sol";
import {
    CraneFixture
} from "../fixtures/CraneFixture.sol";

contract CraneScript
is
FoundryVM,
Fixture,
CamelotV2Fixture,
CraneFixture,
Script
{

    using AddressSetRepo for AddressSet;

    function initialize() public virtual
    override(
        Fixture,
        CamelotV2Fixture,
        CraneFixture
    ) {

    }

    function setUp() public virtual {}


    function run() public virtual {
        // CraneFixture.initialize();
    }

    function processDeclaredAddrsToJSON() public {
        for(uint256 i = 0; i < _declaredAddrs._length(); i++) {
            setDeploymentJSON(
                vm.serializeAddress(
                    "declaredAddrs",
                    vm.getLabel(_declaredAddrs._index(i)),
                    _declaredAddrs._index(i)
                )
            );
        }
    }

    function writeDeploymentJSON() public {
        term.mkDir(term.dirName(deploymentPath()));
        term.touch(deploymentPath());
        vm.writeJson(
            deploymentJSON(),
            deploymentPath()
        );
    }

}