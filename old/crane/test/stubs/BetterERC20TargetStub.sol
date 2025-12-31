// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/token/ERC20/BetterERC20.sol";

/**
 * @title BetterERC20TargetStub
 * @dev Test stub for BetterERC20 with initialization for testing
 */
contract BetterERC20TargetStub is BetterERC20 {
    /**
     * @dev Constructor that initializes the token
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param decimals_ The number of decimals for the token
     * @param initialSupply_ The initial supply of tokens (optional)
     * @param recipient_ The recipient of the initial supply (optional)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address recipient_
    ) {
        _initERC20(name_, symbol_, decimals_, initialSupply_, recipient_);
    }

    /**
     * @dev Mint tokens to a specified address (test-only)
     */
    function mint(address to, uint256 amount) public {
        _mint(to, amount, 0);
    }
}
