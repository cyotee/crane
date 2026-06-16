// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.35;

import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {MockAuthChild} from "./utils/mocks/MockAuthChild.sol";
import {MockAuthority} from "./utils/mocks/MockAuthority.sol";
import {Vm} from "forge-std/Vm.sol";

import {Authority} from "../auth/Auth.sol";

contract OutOfOrderAuthority is Authority {
    function canCall(address, address, bytes4) public pure override returns (bool) {
        revert("OUT_OF_ORDER");
    }
}

contract AuthTest is DSTestPlus {
    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    MockAuthChild mockAuthChild;

    function setUp() public {
        mockAuthChild = new MockAuthChild();
    }

    function testTransferOwnershipAsOwner() public {
        mockAuthChild.transferOwnership(address(0xBEEF));
        assertEq(mockAuthChild.owner(), address(0xBEEF));
    }

    function testSetAuthorityAsOwner() public {
        mockAuthChild.setAuthority(Authority(address(0xBEEF)));
        assertEq(address(mockAuthChild.authority()), address(0xBEEF));
    }

    function testCallFunctionAsOwner() public {
        mockAuthChild.updateFlag();
    }

    function testTransferOwnershipWithPermissiveAuthority() public {
        mockAuthChild.setAuthority(new MockAuthority(true));
        mockAuthChild.transferOwnership(address(0));
        mockAuthChild.transferOwnership(address(this));
    }

    function testSetAuthorityWithPermissiveAuthority() public {
        mockAuthChild.setAuthority(new MockAuthority(true));
        mockAuthChild.transferOwnership(address(0));
        mockAuthChild.setAuthority(Authority(address(0xBEEF)));
    }

    function testCallFunctionWithPermissiveAuthority() public {
        mockAuthChild.setAuthority(new MockAuthority(true));
        mockAuthChild.transferOwnership(address(0));
        mockAuthChild.updateFlag();
    }

    function testSetAuthorityAsOwnerWithOutOfOrderAuthority() public {
        mockAuthChild.setAuthority(new OutOfOrderAuthority());
        mockAuthChild.setAuthority(new MockAuthority(true));
    }

    function test_RevertTransferOwnershipAsNonOwner() public {
        mockAuthChild.transferOwnership(address(0));
        vm.expectRevert();
        mockAuthChild.transferOwnership(address(0xBEEF));
    }

    function test_RevertSetAuthorityAsNonOwner() public {
        mockAuthChild.transferOwnership(address(0));
        vm.expectRevert();
        mockAuthChild.setAuthority(Authority(address(0xBEEF)));
    }

    function test_RevertCallFunctionAsNonOwner() public {
        mockAuthChild.transferOwnership(address(0));
        vm.expectRevert();
        mockAuthChild.updateFlag();
    }

    function test_RevertTransferOwnershipWithRestrictiveAuthority() public {
        mockAuthChild.setAuthority(new MockAuthority(false));
        mockAuthChild.transferOwnership(address(0));
        vm.expectRevert();
        mockAuthChild.transferOwnership(address(this));
    }

    function test_RevertSetAuthorityWithRestrictiveAuthority() public {
        mockAuthChild.setAuthority(new MockAuthority(false));
        mockAuthChild.transferOwnership(address(0));
        vm.expectRevert();
        mockAuthChild.setAuthority(Authority(address(0xBEEF)));
    }

    function test_RevertCallFunctionWithRestrictiveAuthority() public {
        mockAuthChild.setAuthority(new MockAuthority(false));
        mockAuthChild.transferOwnership(address(0));
        vm.expectRevert();
        mockAuthChild.updateFlag();
    }

    function test_RevertTransferOwnershipAsOwnerWithOutOfOrderAuthority() public {
        mockAuthChild.setAuthority(new OutOfOrderAuthority());
        vm.expectRevert();
        mockAuthChild.transferOwnership(address(0));
    }

    function test_RevertCallFunctionAsOwnerWithOutOfOrderAuthority() public {
        mockAuthChild.setAuthority(new OutOfOrderAuthority());
        vm.expectRevert();
        mockAuthChild.updateFlag();
    }

    function testTransferOwnershipAsOwner(address newOwner) public {
        mockAuthChild.transferOwnership(newOwner);
        assertEq(mockAuthChild.owner(), newOwner);
    }

    function testSetAuthorityAsOwner(Authority newAuthority) public {
        mockAuthChild.setAuthority(newAuthority);
        assertEq(address(mockAuthChild.authority()), address(newAuthority));
    }

    function testTransferOwnershipWithPermissiveAuthority(address deadOwner, address newOwner) public {
        if (deadOwner == address(this)) deadOwner = address(0);

        mockAuthChild.setAuthority(new MockAuthority(true));
        mockAuthChild.transferOwnership(deadOwner);
        mockAuthChild.transferOwnership(newOwner);
    }

    function testSetAuthorityWithPermissiveAuthority(address deadOwner, Authority newAuthority) public {
        if (deadOwner == address(this)) deadOwner = address(0);

        mockAuthChild.setAuthority(new MockAuthority(true));
        mockAuthChild.transferOwnership(deadOwner);
        mockAuthChild.setAuthority(newAuthority);
    }

    function testCallFunctionWithPermissiveAuthority(address deadOwner) public {
        if (deadOwner == address(this)) deadOwner = address(0);

        mockAuthChild.setAuthority(new MockAuthority(true));
        mockAuthChild.transferOwnership(deadOwner);
        mockAuthChild.updateFlag();
    }

    function test_RevertTransferOwnershipAsNonOwner(address deadOwner, address newOwner) public {
        vm.assume(deadOwner != address(this));

        mockAuthChild.transferOwnership(deadOwner);
        vm.expectRevert();
        mockAuthChild.transferOwnership(newOwner);
    }

    function test_RevertSetAuthorityAsNonOwner(address deadOwner, Authority newAuthority) public {
        vm.assume(deadOwner != address(this));

        mockAuthChild.transferOwnership(deadOwner);
        vm.expectRevert();
        mockAuthChild.setAuthority(newAuthority);
    }

    function test_RevertCallFunctionAsNonOwner(address deadOwner) public {
        vm.assume(deadOwner != address(this));

        mockAuthChild.transferOwnership(deadOwner);
        vm.expectRevert();
        mockAuthChild.updateFlag();
    }

    function test_RevertTransferOwnershipWithRestrictiveAuthority(address deadOwner, address newOwner) public {
        vm.assume(deadOwner != address(this));

        mockAuthChild.setAuthority(new MockAuthority(false));
        mockAuthChild.transferOwnership(deadOwner);
        vm.expectRevert();
        mockAuthChild.transferOwnership(newOwner);
    }

    function test_RevertSetAuthorityWithRestrictiveAuthority(address deadOwner, Authority newAuthority) public {
        vm.assume(deadOwner != address(this));

        mockAuthChild.setAuthority(new MockAuthority(false));
        mockAuthChild.transferOwnership(deadOwner);
        vm.expectRevert();
        mockAuthChild.setAuthority(newAuthority);
    }

    function test_RevertCallFunctionWithRestrictiveAuthority(address deadOwner) public {
        vm.assume(deadOwner != address(this));

        mockAuthChild.setAuthority(new MockAuthority(false));
        mockAuthChild.transferOwnership(deadOwner);
        vm.expectRevert();
        mockAuthChild.updateFlag();
    }

    function test_RevertTransferOwnershipAsOwnerWithOutOfOrderAuthority(address deadOwner) public {
        mockAuthChild.setAuthority(new OutOfOrderAuthority());
        vm.expectRevert();
        mockAuthChild.transferOwnership(deadOwner);
    }
}
