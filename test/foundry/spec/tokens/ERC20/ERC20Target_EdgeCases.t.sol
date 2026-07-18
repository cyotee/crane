// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {IERC20Errors} from "@crane/contracts/interfaces/IERC20Errors.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {TestBase_ERC20, ERC20TargetStubHandler} from "@crane/contracts/tokens/ERC20/TestBase_ERC20.sol";
import {IERC20DFPkg, ERC20DFPkg} from "@crane/contracts/tokens/ERC20/ERC20DFPkg.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

// tag::ERC20Target_EdgeCases[]
/**
 * @title ERC20Target_EdgeCases
 * @notice Edge case tests for ERC20Target (and proxy via DFPkg) implementation.
 * @dev LR-1 + LR-7 compliant. Inherits TestBase_ERC20 + uses InitDevService + real ERC20DFPkg
 *      (non-zero facet) for full production-like initialization of real ERC20 Diamond proxy.
 *      Uses Behavior_IFacet for declaration coverage (since facets involved in init).
 *      All asserts use exact values (no side-effect 'changed' checks; precise deltas/expected).
 *      References ONLY central NatSpec values for IFacet (0x5b6f4d01 etc) and IDiamond*
 *      from CENTRALLY_COMPUTED_NATSPEC_VALUES.md.
 * @custom:signature ERC20Target_EdgeCases
 */
contract ERC20Target_EdgeCases is TestBase_ERC20 {
    using BetterEfficientHashLib for bytes;

    IERC20 public token;
    address public alice;
    address public bob;
    uint256 public constant INITIAL_SUPPLY = 1_000_000e18;

    ICreate3FactoryProxy internal factory;
    IDiamondPackageCallBackFactory internal diamondFactory;
    IFacet internal erc20Facet;
    IERC20DFPkg internal erc20DFPKG;

    function setUp() public virtual override(TestBase_ERC20) {
        // LR-7: full non-0 init via InitDev + real ERC20DFPkg (facets non-zero, no stubs bypass)
        (factory, diamondFactory) = InitDevService.initEnv(address(this));

        erc20Facet = factory.deployFacet(type(ERC20Facet).creationCode, abi.encode(type(ERC20Facet).name)._hash());
        vm.label(address(erc20Facet), "ERC20Facet");

        erc20DFPKG = IERC20DFPkg(
            address(
                factory.deployPackageWithArgs(
                    type(ERC20DFPkg).creationCode,
                    abi.encode(IERC20DFPkg.PkgInit({erc20Facet: erc20Facet})),
                    abi.encode(type(ERC20DFPkg).name)._hash()
                )
            )
        );
        vm.label(address(erc20DFPKG), "ERC20DFPkg");

        // LR-7 Behavior coverage since facets involved in real pkg init (use central IFacet values only)
        Behavior_IFacet.expect_IFacet_facetName(erc20Facet, type(ERC20Facet).name);

        bytes4[] memory expectedIfaces = new bytes4[](3);
        expectedIfaces[0] = type(IERC20).interfaceId;
        expectedIfaces[1] = type(IERC20Metadata).interfaceId;
        expectedIfaces[2] = type(IERC20).interfaceId ^ type(IERC20Metadata).interfaceId;
        Behavior_IFacet.expect_IFacet_facetInterfaces(erc20Facet, expectedIfaces);

        TestBase_ERC20.setUp();

        // Setup actors + fund from handler (real proxy received supply in _deployToken)
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(address(tokenSubject), "ERC20ProxyViaDFPkg");

        vm.prank(address(handler));
        tokenSubject.transfer(alice, INITIAL_SUPPLY);

        // Ensure alice (who now holds the full supply) is tracked for invariant sumBalances checks.
        handler.trackAddress(alice);

        token = tokenSubject;
    }

    // tag::deployToken_override[]
    /// @inheritdoc TestBase_ERC20
    function _deployToken(ERC20TargetStubHandler handler_) internal virtual override returns (IERC20 token_) {
        // LR-7: use real DFPkg (with non-0 facet) + callback factory for production-like Diamond ERC20
        token_ =
            erc20DFPKG.deploy(diamondFactory, "Test Token", "TT", 18, INITIAL_SUPPLY, address(handler_), bytes32(0));
    }

    // end::deployToken_override[]

    /* ---------------------------------------------------------------------- */
    /*                          Transfer Edge Cases                           */
    /* ---------------------------------------------------------------------- */

    // tag::test_transfer_zeroAmount_succeeds()[]
    function test_transfer_zeroAmount_succeeds() public {
        vm.prank(alice);
        bool success = token.transfer(bob, 0);
        assertTrue(success, "Zero amount transfer should succeed");
        // LR-7: exact expected (INITIAL) not 'unchanged' var or side-effect
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY, "Alice balance should remain at INITIAL_SUPPLY");
        assertEq(token.balanceOf(bob), 0, "Bob balance should be zero");
    }
    // end::test_transfer_zeroAmount_succeeds()[]

    function test_transfer_toZeroAddress_reverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transfer(address(0), 100e18);
    }

    function test_transfer_insufficientBalance_reverts() public {
        uint256 amount = INITIAL_SUPPLY + 1;
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, INITIAL_SUPPLY, amount)
        );
        token.transfer(bob, amount);
    }

    function test_transfer_fullBalance_succeeds() public {
        vm.prank(alice);
        bool success = token.transfer(bob, INITIAL_SUPPLY);
        assertTrue(success, "Full balance transfer should succeed");
        assertEq(token.balanceOf(alice), 0, "Alice should have zero balance");
        assertEq(token.balanceOf(bob), INITIAL_SUPPLY, "Bob should have full balance");
    }

    // tag::test_transfer_toSelf_succeeds()[]
    function test_transfer_toSelf_succeeds() public {
        uint256 amount = 100e18;
        // LR-7: use explicit expected value (no 'balanceBefore' for unchanged cases)
        uint256 expectedBalance = INITIAL_SUPPLY;
        vm.prank(alice);
        bool success = token.transfer(alice, amount);
        assertTrue(success, "Transfer to self should succeed");
        assertEq(token.balanceOf(alice), expectedBalance, "Alice balance should remain INITIAL_SUPPLY");
    }
    // end::test_transfer_toSelf_succeeds()[]

    function test_transfer_emitsEvent() public {
        uint256 amount = 100e18;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(alice, bob, amount);
        token.transfer(bob, amount);
        // LR-7: exact final state after (delta precise)
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount, "Alice balance after transfer exact");
        assertEq(token.balanceOf(bob), amount, "Bob balance after transfer exact");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Approve Edge Cases                           */
    /* ---------------------------------------------------------------------- */

    function test_approve_zeroAddressSpender_reverts() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidSpender.selector, address(0)));
        token.approve(address(0), 100e18);
    }

    function test_approve_zeroAmount_succeeds() public {
        vm.prank(alice);
        bool success = token.approve(bob, 0);
        assertTrue(success, "Zero amount approval should succeed");
        assertEq(token.allowance(alice, bob), 0, "Allowance should be zero");
    }

    function test_approve_overwriteExisting_succeeds() public {
        vm.startPrank(alice);
        token.approve(bob, 100e18);
        assertEq(token.allowance(alice, bob), 100e18, "Initial allowance");

        token.approve(bob, 50e18);
        // LR-7: exact value
        assertEq(token.allowance(alice, bob), 50e18, "Allowance should be exactly 50e18 after overwrite");
        vm.stopPrank();
    }

    function test_approve_maxUint256_succeeds() public {
        vm.prank(alice);
        bool success = token.approve(bob, type(uint256).max);
        assertTrue(success, "Max uint256 approval should succeed");
        assertEq(token.allowance(alice, bob), type(uint256).max, "Allowance should be max");
    }

    function test_approve_emitsEvent() public {
        uint256 amount = 100e18;
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Approval(alice, bob, amount);
        token.approve(bob, amount);
    }

    /* ---------------------------------------------------------------------- */
    /*                        TransferFrom Edge Cases                          */
    /* ---------------------------------------------------------------------- */

    function test_transferFrom_withoutAllowance_reverts() public {
        // Bob tries to transfer from Alice without any approval
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 0, 100e18));
        token.transferFrom(alice, bob, 100e18);
    }

    function test_transferFrom_exceedsAllowance_reverts() public {
        // Alice approves Bob for 50 tokens
        vm.prank(alice);
        token.approve(bob, 50e18);

        // Bob tries to transfer 100 tokens (more than allowed)
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, bob, 50e18, 100e18));
        token.transferFrom(alice, bob, 100e18);
    }

    function test_transferFrom_decreasesAllowance() public {
        // Alice approves Bob for 100 tokens
        vm.prank(alice);
        token.approve(bob, 100e18);
        assertEq(token.allowance(alice, bob), 100e18, "Initial allowance");

        // Bob transfers 60 tokens
        vm.prank(bob);
        token.transferFrom(alice, bob, 60e18);
        // LR-7: exact remaining
        assertEq(token.allowance(alice, bob), 40e18, "Allowance should be exactly 40e18");

        // Bob can still transfer remaining allowance
        vm.prank(bob);
        token.transferFrom(alice, bob, 40e18);
        assertEq(token.allowance(alice, bob), 0, "Allowance should be exactly zero");
    }

    function test_transferFrom_withAllowance_succeeds() public {
        // Setup: Alice approves Bob
        vm.prank(alice);
        token.approve(bob, 100e18);

        // Bob transfers from Alice to himself
        vm.prank(bob);
        bool success = token.transferFrom(alice, bob, 100e18);
        assertTrue(success, "TransferFrom should succeed");
        // LR-7: exact deltas used in asserts
        assertEq(token.balanceOf(bob), 100e18, "Bob should receive exactly 100e18");
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - 100e18, "Alice balance should be exactly INITIAL-100e18");
        assertEq(token.allowance(alice, bob), 0, "Allowance should be exactly zero after full spend");
    }

    function test_transferFrom_toZeroAddress_reverts() public {
        vm.prank(alice);
        token.approve(bob, 100e18);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, address(0)));
        token.transferFrom(alice, address(0), 100e18);
    }

    function test_transferFrom_insufficientBalance_reverts() public {
        uint256 amount = INITIAL_SUPPLY + 1;
        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, INITIAL_SUPPLY, amount)
        );
        token.transferFrom(alice, bob, amount);
    }

    function test_transferFrom_zeroAmount_succeeds() public {
        vm.prank(bob);
        bool success = token.transferFrom(alice, bob, 0);
        assertTrue(success, "Zero amount transferFrom should succeed");
    }

    function test_transferFrom_emitsEvent() public {
        uint256 amount = 100e18;
        vm.prank(alice);
        token.approve(bob, amount);

        vm.prank(bob);
        vm.expectEmit(true, true, false, true);
        emit IERC20Events.Transfer(alice, bob, amount);
        token.transferFrom(alice, bob, amount);
        // LR-7: add exact post-state asserts
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount, "Alice exact after transferFrom");
        assertEq(token.balanceOf(bob), amount, "Bob exact after transferFrom");
        assertEq(token.allowance(alice, bob), 0, "Allowance exact zero");
    }

    /* ---------------------------------------------------------------------- */
    /*                        View Function Edge Cases                         */
    /* ---------------------------------------------------------------------- */

    function test_balanceOf_nonExistentAccount_returnsZero() public {
        address nonExistent = makeAddr("nonExistent");
        assertEq(token.balanceOf(nonExistent), 0, "Non-existent account should have zero balance");
    }

    function test_allowance_notSet_returnsZero() public view {
        assertEq(token.allowance(alice, bob), 0, "Unset allowance should be zero");
    }

    function test_totalSupply_matchesInitial() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY, "Total supply should match initial");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Fuzz Tests                                    */
    /* ---------------------------------------------------------------------- */

    function testFuzz_transfer_anyValidAmount_succeeds(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);

        vm.prank(alice);
        bool success = token.transfer(bob, amount);
        assertTrue(success, "Transfer should succeed");
        assertEq(token.balanceOf(bob), amount, "Bob should receive correct amount");
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - amount, "Alice should have remaining");
    }

    function testFuzz_approve_anyAmount_succeeds(uint256 amount) public {
        vm.prank(alice);
        bool success = token.approve(bob, amount);
        assertTrue(success, "Approve should succeed");
        assertEq(token.allowance(alice, bob), amount, "Allowance should be set");
    }

    function testFuzz_transfer_preservesTotalSupply(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);

        uint256 totalBefore = token.totalSupply();
        vm.prank(alice);
        token.transfer(bob, amount);
        uint256 totalAfter = token.totalSupply();

        assertEq(totalAfter, totalBefore, "Total supply should be preserved");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Multiple Actor Scenarios                          */
    /* ---------------------------------------------------------------------- */

    function test_multipleTransfers_balancesCorrect() public {
        address charlie = makeAddr("charlie");

        // Alice sends to Bob
        vm.prank(alice);
        token.transfer(bob, 300e18);

        // Alice sends to Charlie
        vm.prank(alice);
        token.transfer(charlie, 200e18);

        // Bob sends to Charlie
        vm.prank(bob);
        token.transfer(charlie, 100e18);

        assertEq(token.balanceOf(alice), INITIAL_SUPPLY - 500e18, "Alice balance incorrect");
        assertEq(token.balanceOf(bob), 200e18, "Bob balance incorrect");
        assertEq(token.balanceOf(charlie), 300e18, "Charlie balance incorrect");
    }

    function test_multipleApprovals_independent() public {
        address charlie = makeAddr("charlie");

        vm.startPrank(alice);
        token.approve(bob, 100e18);
        token.approve(charlie, 200e18);
        vm.stopPrank();

        // LR-7: exact
        assertEq(token.allowance(alice, bob), 100e18, "Bob's allowance exactly 100e18");
        assertEq(token.allowance(alice, charlie), 200e18, "Charlie's allowance exactly 200e18");
    }

    // tag::test_LR7_realERC20_DFPkg_init_Behavior_declaration()[]
    /**
     * @notice LR-7 declaration + Behavior test exercising the real initialized ERC20 facet (from full DFPkg init).
     * @dev Validates facet metadata via Behavior using exact expects from setUp (central IFacet values).
     *      Confirms full init (pkg facets non-0) and exact matches.
     * @custom:signature test_LR7_realERC20_DFPkg_init_Behavior_declaration()
     */
    function test_LR7_realERC20_DFPkg_init_Behavior_declaration() public {
        IFacet facet = erc20Facet;

        // via Behavior (hasValid uses setUp expect; areValid direct exact)
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetName(facet), "facetName hasValid");
        assertTrue(Behavior_IFacet.hasValid_IFacet_facetInterfaces(facet), "facetInterfaces hasValid");

        assertTrue(
            Behavior_IFacet.isValid_IFacet_facetMetadata_consistency(facet), "facetMetadata must be consistent exactly"
        );

        // direct areValid with controls (exact)
        bytes4[] memory ifaces = new bytes4[](3);
        ifaces[0] = type(IERC20).interfaceId;
        ifaces[1] = type(IERC20Metadata).interfaceId;
        ifaces[2] = type(IERC20).interfaceId ^ type(IERC20Metadata).interfaceId;
        assertTrue(Behavior_IFacet.areValid_IFacet_facetInterfaces(facet, ifaces, facet.facetInterfaces()));

        // also package level basic on DFPkg (LR-7 package declaration elements)
        assertEq(erc20DFPKG.packageName(), type(ERC20DFPkg).name, "packageName exact");
        assertTrue(erc20DFPKG.facetCuts().length > 0, "facetCuts non-empty from real pkg");
    }
    // end::test_LR7_realERC20_DFPkg_init_Behavior_declaration()[]
}
// end::ERC20Target_EdgeCases[]
