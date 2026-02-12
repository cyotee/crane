// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {ERC721TargetStub} from "@crane/contracts/tokens/ERC721/ERC721TargetStub.sol";
import {ERC721TargetStubHandler} from "@crane/contracts/tokens/ERC721/ERC721TargetStubHandler.sol";

/**
 * @title TestBase_ERC721
 * @notice Base test contract for ERC721 invariant testing
 * @dev Follows the same pattern as TestBase_ERC20 for consistency
 */
abstract contract TestBase_ERC721 is Test {
    ERC721TargetStubHandler public handler;
    ERC721TargetStub public tokenSubject;

    // Override in derived tests to deploy the token
    function _deployToken(ERC721TargetStubHandler handler_) internal virtual returns (ERC721TargetStub token_);

    function _deployHandler() internal virtual returns (ERC721TargetStubHandler handler_) {
        handler_ = new ERC721TargetStubHandler();
    }

    function _registerToken(ERC721TargetStubHandler handler_, ERC721TargetStub token_) internal virtual {
        handler_.attachToken(token_);
    }

    function setUp() public virtual {
        handler = _deployHandler();
        tokenSubject = _deployToken(handler);
        _registerToken(handler, tokenSubject);

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

    /* ---------------------------------------------------------------------- */
    /*                              Invariants                                 */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Sum of all balances should equal total minted minus burned
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

    /**
     * @notice Each token should have exactly one owner
     */
    function invariant_token_has_single_owner() public view {
        uint256 tokenCount = handler.tokenCount();

        for (uint256 i = 0; i < tokenCount; i++) {
            uint256 tokenId = handler.tokenAt(i);
            if (handler.tokenExists(tokenId)) {
                address owner = handler.ownerOf(tokenId);
                assertNotEq(owner, address(0), "Existing token should have non-zero owner");
            }
        }
    }

    /**
     * @notice Balances should be non-negative (always true for uint, but explicit)
     */
    function invariant_balances_nonnegative() public view {
        uint256 actorCount = handler.actorCount();

        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actorAt(i);
            uint256 balance = handler.balanceOf(actor);
            assertGe(balance, 0, "Balance should be non-negative");
        }
    }

    /**
     * @notice Ghost variables should be consistent
     */
    function invariant_ghost_consistent() public view {
        assertGe(handler.ghostTotalMinted(), handler.ghostTotalBurned(), "Minted should be >= burned");
    }
}
