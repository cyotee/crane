// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {BetterERC4626TargetStub} from "contracts/crane/test/stubs/BetterERC4626TargetStub.sol";
import {BetterERC20TargetStub} from "contracts/crane/test/stubs/BetterERC20TargetStub.sol";

/**
 * @title BetterERC4626TargetTest
 * @dev Base test contract for BetterERC4626Target tests
 */
contract BetterERC4626TargetTest is Test_Crane {
    // Test fixtures
    BetterERC4626TargetStub vault;
    BetterERC20TargetStub underlying;

    // Constants
    string public constant VAULT_NAME = "Test Vault";
    string public constant VAULT_SYMBOL = "vTST";
    string public constant UNDERLYING_NAME = "Test Token";
    string public constant UNDERLYING_SYMBOL = "TST";
    uint8 public constant UNDERLYING_DECIMALS = 18;
    uint8 public constant DECIMALS_OFFSET = 0;
    uint256 public constant INITIAL_UNDERLYING_SUPPLY = 1000 * 10 ** 18;
    /// forge-lint: disable-next-line(mixed-case-variable)
    address public DEPOSITOR;

    function setUp() public virtual override {
        DEPOSITOR = trader();

        // Create underlying token with initial supply
        underlying = new BetterERC20TargetStub(
            UNDERLYING_NAME, UNDERLYING_SYMBOL, UNDERLYING_DECIMALS, INITIAL_UNDERLYING_SUPPLY, DEPOSITOR
        );

        // Create vault
        vault = new BetterERC4626TargetStub(address(underlying), VAULT_NAME, VAULT_SYMBOL, DECIMALS_OFFSET);
    }
}
