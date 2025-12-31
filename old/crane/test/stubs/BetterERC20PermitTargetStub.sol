// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/token/ERC20/extensions/BetterERC20Permit.sol";

/**
 * @title BetterERC20PermitTargetStub
 * @dev Test stub for BetterERC20Permit with initialization for testing
 */
contract BetterERC20PermitTargetStub is BetterERC20Permit {
    /**
     * @dev Constructor that initializes the token with permit capability
     * @param name_ The name of the token
     * @param symbol_ The symbol of the token
     * @param decimals_ The number of decimals for the token
     * @param initialSupply_ The initial supply of tokens
     * @param recipient_ The recipient of the initial supply
     * @param version_ The EIP712 version string
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address recipient_,
        string memory version_
    ) {
        _initERC20(name_, symbol_, decimals_, initialSupply_, recipient_);
        _initEIP721(name_, version_);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
