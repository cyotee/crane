// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ERC721} from "@crane/contracts/tokens/ERC721/TestBase_ERC721.sol";
import {ERC721TargetStub} from "@crane/contracts/tokens/ERC721/ERC721TargetStub.sol";
import {ERC721TargetStubHandler} from "@crane/contracts/tokens/ERC721/ERC721TargetStubHandler.sol";

/**
 * @title ERC721Invariant_Test
 * @notice Invariant tests for ERC721 implementation
 */
contract ERC721Invariant_Test is TestBase_ERC721 {

    function _deployToken(ERC721TargetStubHandler handler_) internal override returns (ERC721TargetStub token_) {
        token_ = new ERC721TargetStub();
    }

    // Inherits all invariants from TestBase_ERC721:
    // - invariant_sumBalances_equals_supply
    // - invariant_token_has_single_owner
    // - invariant_balances_nonnegative
    // - invariant_ghost_consistent
}
