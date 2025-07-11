// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { Test_Crane } from "../../../../../contracts/test/Test_Crane.sol";
import "../../../../../contracts/token/ERC20/BetterERC20.sol";
import "../../../../../contracts/test/stubs/BetterERC20TargetStub.sol";

/**
 * @title BetterERC20TargetTest
 * @dev Base test contract for BetterERC20Target tests
 */
contract BetterERC20TargetTest is Test_Crane {
    // Test fixtures
    BetterERC20TargetStub token;
    
    // Constants
    string public constant NAME = "Test Token";
    string public constant SYMBOL = "TST";
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 0;
    address public RECIPIENT;
    
    function setUp() public virtual override {
        RECIPIENT = trader();
        token = new BetterERC20TargetStub(NAME, SYMBOL, DECIMALS, INITIAL_SUPPLY, RECIPIENT);
    }
} 