// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../../../../../../test/DAOSYSTest.sol";
// import "daosys/access/ownable/behaviors/IOwnable.b.sol";
import "../../../../../contracts/test/CraneTest.sol";

import "../../../../../contracts/access/ownable/test/stubs/OwnableTargetStub.sol";
import {IOwnable} from "../../../../../contracts/access/ownable/IOwnable.sol";

contract OwnableTargetTest
is
CraneTest

{

    address owner_ = vm.addr(uint256(keccak256(abi.encode("owner"))));
    // address proposedOwner = vm.addr(uint256(keccak256(abi.encode("proposedOwner"))));

    OwnableTargetStub ownableStub;

    function setUp()
    public virtual override {

        declareUsed(address(owner_));
        ownableStub = new OwnableTargetStub(owner_);
        declareUsed(address(ownableStub));

    }

    /* ---------------------------------------------------------------------- */
    /*                             IOwnable.owner                             */
    /* ---------------------------------------------------------------------- */

    function test_IOwnable_owner()
    public view {
        assertEq(
            owner_,
            ownableStub.owner()
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IOwnable.proposedOwner                         */
    /* ---------------------------------------------------------------------- */

    function test_IOwnable_proposedOwner(
        address proposedOwner_
    ) public
    isValid(proposedOwner_)
    {
        vm.startPrank(owner_);
        ownableStub.transferOwnership(proposedOwner_);
        assertEq(
            proposedOwner_,
            ownableStub.proposedOwner()
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                       IOwnable.transferOwnership                       */
    /* ---------------------------------------------------------------------- */

    function test_IOwnable_transferOwnership(
        address proposedOwner_
    ) public
    isValid(proposedOwner_)
    {
        vm.startPrank(owner_);
        vm.expectEmit(true, true, false, false, address(ownableStub));
        emit IOwnable.TransferProposed(
            proposedOwner_
        );
        ownableStub.transferOwnership(proposedOwner_);
        assertEq(
            proposedOwner_,
            ownableStub.proposedOwner()
        );
    }

    function test_IOwnable_transferOwnership_NotOwner_address0(
        address proposedOwner_
    ) public {
        vm.startPrank(address(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.NotOwner.selector,
                address(0)
            )
        );
        ownableStub.transferOwnership(proposedOwner_);
        assertEq(
            owner_,
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    function test_IOwnable_transferOwnership_NotOwner(
        address notOwner_,
        address proposedOwner_
    ) public {
        vm.assume(notOwner_ != address(0));
        vm.assume(notOwner_ != owner_);
        vm.startPrank(notOwner_);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.NotOwner.selector,
                notOwner_
            )
        );
        ownableStub.transferOwnership(proposedOwner_);
        assertEq(
            owner_,
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    function test_IOwnable_transferOwnership_NotProposed_address0() public {
        // vm.assume(notOwner_ != address(0));
        // vm.assume(notOwner_ != owner);
        vm.startPrank(owner_);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.NotProposed.selector,
                address(0)
            )
        );
        ownableStub.transferOwnership(address(0));
        assertEq(
            owner_,
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                        IOwnable.acceptOwnership                        */
    /* ---------------------------------------------------------------------- */

    function test_IOwnable_acceptOwnership(
        address newOwner_
    ) public
    isValid(newOwner_)
    {
        vm.startPrank(owner_);
        vm.expectEmit(true, true, false, false, address(ownableStub));
        emit IOwnable.TransferProposed(
            newOwner_
        );
        ownableStub.transferOwnership(newOwner_);
        assertEq(
            newOwner_,
            ownableStub.proposedOwner()
        );
        vm.startPrank(newOwner_);
        vm.expectEmit(true, true, false, false, address(ownableStub));
        emit IOwnable.OwnershipTransferred(
            owner_,
            newOwner_
        );
        ownableStub.acceptOwnership();
        assertEq(
            newOwner_,
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    function test_IOwnable_acceptOwnership_NotProposed_address0()
    public {
        vm.startPrank(address(0));
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.NotProposed.selector,
                address(0)
            )
        );
        ownableStub.acceptOwnership();
        assertEq(
            owner_,
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    function test_IOwnable_acceptOwnership_NotProposed(
        address neverProposed
    ) public {
        vm.assume(neverProposed != address(0));
        vm.assume(neverProposed != owner_);
        vm.startPrank(neverProposed);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.NotProposed.selector,
                neverProposed
            )
        );
        ownableStub.acceptOwnership();
        assertEq(
            owner_,
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                       IOwnable.renounceOwnership                       */
    /* ---------------------------------------------------------------------- */

    function test_IOwnable_renounceOwnership()
    public {
        vm.startPrank(owner_);
        vm.expectEmit(true, true, false, false, address(ownableStub));
        emit IOwnable.OwnershipTransferred(
            owner_,
            address(0)
        );
        ownableStub.renounceOwnership();
        assertEq(
            address(0),
            ownableStub.owner()
        );
        assertEq(
            address(0),
            ownableStub.proposedOwner()
        );
    }

    function test_IOwnable_renounceOwnership_proposed_owner(
        address newOwner_
    ) public {
        vm.assume(newOwner_ != address(0));
        vm.assume(newOwner_ != owner_);
        vm.expectEmit(true, true, false, false, address(ownableStub));
        emit IOwnable.TransferProposed(
            newOwner_
        );
        vm.startPrank(owner_);
        ownableStub.transferOwnership(newOwner_);
        vm.expectRevert(
            abi.encodeWithSelector(
                IOwnable.NotProposed.selector,
                address(0)
            )
        );
        ownableStub.renounceOwnership();
        assertEq(
            owner_,
            ownableStub.owner()
        );
        assertEq(
            newOwner_,
            ownableStub.proposedOwner()
        );
    }

}