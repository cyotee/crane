// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {ERC721TargetStub} from "@crane/contracts/tokens/ERC721/ERC721TargetStub.sol";
import {ERC721TargetStubHandler} from "@crane/contracts/tokens/ERC721/ERC721TargetStubHandler.sol";
import {Behavior_IERC721} from "@crane/contracts/tokens/ERC721/Behavior_IERC721.sol";

// tag::TestBase_ERC721[]
/**
 * @title TestBase_ERC721
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Abstract base for ERC721 handler-based invariant/fuzz testing (LR-7).
 * @dev Follows exact pattern of TestBase_ERC20 gold (virtual deploy/attach/handler registration + invariants using ghost state + exact assertEq).
 *      LR-7: full init enforcement (non-zero subject guard referencing CraneTest/InitDevService when using real facets/Pkgs), exact value asserts (not side effects), mandatory Behavior_* calls + isValid_ wrappers for surface (balance/owner/approved/transfer etc), declaration-style tests via Behavior.
 *      LR-1: rich NatSpec + exact // tag:: / end:: (library not, contract + all symbols) on public surface/invariants/tests/virtuals. Hyphenated where modeled. Modeled on TestBase_IERC165 + TestBase_IFacet + TestBase_ERC20 golds + AGENTS.md TestBase pattern.
 *      Init: when used with CraneTest (full factory/pkg bootstrap for real ERC721Facet via DFPkg), call parent setUp and use non-0 facets; for stub invariant mode, the virtuals provide the SUT (no address(0)).
 *      Preserves 100% original logic (ghosts, actor tracking, selector registration).
 */
abstract contract TestBase_ERC721 is Test {
    ERC721TargetStubHandler public handler;
    ERC721TargetStub public tokenSubject;

    // tag::setUp()[]
    /**
     * @notice Deploys handler + SUT via virtuals, registers for fuzz, primes for Behavior validation.
     * @dev LR-7: asserts non-zero tokenSubject (full init); registers handlers/selectors (mint/transfer/approve/set/burn).
     *      Supports CraneTest style: inheritors can override + super or deploy real via packages before calling.
     */
    function setUp() public virtual {
        handler = _deployHandler();
        tokenSubject = _deployToken(handler);
        _registerToken(handler, tokenSubject);

        // LR-7 full init enforcement (real non-zero SUT; use CraneTest + InitDevService + DFPkg for facet-backed)
        assertTrue(
            address(tokenSubject) != address(0),
            "LR-7: tokenSubject must be real non-zero (CraneTest/TestBase chaining + InitDev + deploy or stub)"
        );

        // Register handler as the fuzz target
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = handler.mint.selector;
        selectors[1] = handler.transferFrom.selector;
        selectors[2] = handler.approve.selector;
        selectors[3] = handler.setApprovalForAll.selector;
        selectors[4] = handler.burn.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }
    // end::setUp()[]

    // tag::_deployToken(ERC721TargetStubHandler)[]
    // Override in derived tests to deploy the token
    /**
     * @notice Virtual hook: deploy and return the ERC721 SUT (stub or real facet proxy).
     * @param handler_ The handler that will attach/own the token.
     * @return token_ The deployed token subject.
     */
    function _deployToken(ERC721TargetStubHandler handler_) internal virtual returns (ERC721TargetStub token_);
    // end::_deployToken(ERC721TargetStubHandler)[]

    // tag::_deployHandler()[]
    /**
     * @notice Virtual hook for handler deployment (override to customize).
     * @return handler_ The handler instance.
     */
    function _deployHandler() internal virtual returns (ERC721TargetStubHandler handler_) {
        handler_ = new ERC721TargetStubHandler();
    }
    // end::_deployHandler()[]

    // tag::_registerToken(ERC721TargetStubHandler-ERC721TargetStub)[]
    /**
     * @notice Virtual hook to attach/register the token with handler.
     * @param handler_ The handler.
     * @param token_ The token.
     */
    function _registerToken(ERC721TargetStubHandler handler_, ERC721TargetStub token_) internal virtual {
        handler_.attachToken(token_);
    }
    // end::_registerToken(ERC721TargetStubHandler-ERC721TargetStub)[]

    /* ---------------------------------------------------------------------- */
    /*                              Invariants                                 */
    /* ---------------------------------------------------------------------- */

    // tag::invariant_sumBalances_equals_supply()[]
    /**
     * @notice Invariant: sum of balances across actors == ghost minted - burned (exact).
     * @dev Uses exact assertEq per LR-7 (no side effect only check). Can wrap Behavior for balance queries.
     */
    function invariant_sumBalances_equals_supply() public view {
        uint256 actorCount = handler.actorCount();
        uint256 sumBalances = 0;

        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actorAt(i);
            sumBalances += handler.balanceOf(actor);
        }

        uint256 expectedSupply = handler.ghostTotalMinted() - handler.ghostTotalBurned();
        assertEq(sumBalances, expectedSupply, "Sum of balances should equal minted - burned");
    }
    // end::invariant_sumBalances_equals_supply()[]

    // tag::invariant_token_has_single_owner()[]
    /**
     * @notice Invariant: every existing token has exactly one non-zero owner.
     * @dev Uses Behavior_IERC721.isValid_ownerOf for owner validation (LR-7 mandatory Behavior use + exact).
     */
    function invariant_token_has_single_owner() public view {
        uint256 tokenCount = handler.tokenCount();

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = handler.tokenAt(i);
            if (handler.tokenExists(tokenId)) {
                address owner = handler.ownerOf(tokenId);
                // exact non-zero via Behavior wrapped
                bool ownerValid = Behavior_IERC721.isValid_ownerOf(IERC721(address(tokenSubject)), tokenId, owner) && owner != address(0);
                assertTrue(ownerValid, "Existing token should have non-zero owner (via Behavior_IERC721)");
                assertNotEq(owner, address(0), "Existing token should have non-zero owner");
            }
        }
    }
    // end::invariant_token_has_single_owner()[]

    // tag::invariant_balances_nonnegative()[]
    /**
     * @notice Invariant: balances >= 0 (uint always, explicit + Behavior balance check).
     * @dev LR-7 exact.
     */
    function invariant_balances_nonnegative() public view {
        uint256 actorCount = handler.actorCount();

        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actorAt(i);
            uint256 balance = handler.balanceOf(actor);
            // wrap with Behavior for LR-7
            assertTrue(
                Behavior_IERC721.isValid_balanceOf(IERC721(address(tokenSubject)), actor, balance),
                "Balance query must be valid per Behavior_IERC721"
            );
            assertGe(balance, 0, "Balance should be non-negative");
        }
    }
    // end::invariant_balances_nonnegative()[]

    // tag::invariant_ghost_consistent()[]
    /**
     * @notice Invariant: minted >= burned (ghosts).
     */
    function invariant_ghost_consistent() public view {
        assertGe(handler.ghostTotalMinted(), handler.ghostTotalBurned(), "Minted should be >= burned");
    }
    // end::invariant_ghost_consistent()[]
}
// end::TestBase_ERC721[]
