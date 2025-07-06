// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { Test_Crane } from "../../../../../../contracts/test/Test_Crane.sol";
import "../../../../../../contracts/token/ERC20/extensions/BetterERC20Permit.sol";
import "../../../../../../contracts/test/stubs/BetterERC20PermitTargetStub.sol";

/**
 * @title BetterERC20PermitTargetTest
 * @dev Base test contract for BetterERC20PermitTarget tests
 */
contract BetterERC20PermitTargetTest is Test_Crane {
    // Test fixtures
    BetterERC20PermitTargetStub token;
    
    // Constants
    string public constant NAME = "Test Token";
    string public constant SYMBOL = "TST";
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 0;
    address public RECIPIENT;
    string public constant VERSION = "1";
    
    function setUp() public virtual override {
        RECIPIENT = trader();
        token = new BetterERC20PermitTargetStub(
            NAME, 
            SYMBOL, 
            DECIMALS, 
            INITIAL_SUPPLY, 
            RECIPIENT, 
            VERSION
        );
    }
} 