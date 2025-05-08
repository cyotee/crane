// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {LOCAL} from "../../LOCAL.sol";
import {ARB_OS_PRECOMPILES} from "../ARB_OS_PRECOMPILES.sol";

import {
    Fixture
} from "../../../fixtures/Fixture.sol";

import {
    ArbOSVM
} from "../../../utils/vm/arbOS/ArbOSVM.sol";

import {
    IArbOwnerPublic
} from "../../../utils/vm/arbOS/interfaces/IArbOwnerPublic.sol";

import {
    ArbOwnerPublicStub
} from "../../../utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol";

contract ArbOSFixture
is
Fixture,
ArbOSVM
{

    function initialize() public virtual
    override(
        Fixture
    ) {
        initPrecompiles_ArbOS();
    }

    uint64 constant DEFAULT_SHARE_PRICE = 1060183780;

    function initPrecompiles_ArbOS()
    public {
        vm.etch(
            address(arbOwnerPublic()),
            address(arbOwnerPublicStub()).code
        );
        setSharePrice(DEFAULT_SHARE_PRICE);
    }

    function setSharePrice(
        uint64 newSharePrice
    ) public returns(bool) {
        ArbOwnerPublicStub(ARB_OS_PRECOMPILES.ARB_OWNER_PUBLIC)
        .setSharePrice(newSharePrice);
        return true;
    }

    function arbOwnerPublic()
    public virtual
    returns(IArbOwnerPublic) {
        return IArbOwnerPublic(ARB_OS_PRECOMPILES.ARB_OWNER_PUBLIC);
    }

    IArbOwnerPublic internal _arbOwnerPublic;

    function arbOwnerPublicStub()
    public virtual
    returns(IArbOwnerPublic) {
        if(block.chainid == LOCAL.CHAIN_ID) {
            revert("ArbOSFixture: ArbOwnerPublicStub is NOT supported on LOCAL");
        }
        if(address(_arbOwnerPublic) == address(0)) {
            if(block.chainid != LOCAL.CHAIN_ID) {
                _arbOwnerPublic = new ArbOwnerPublicStub();
                initPrecompiles_ArbOS();
            }
        }
        return _arbOwnerPublic;
    }
    
}