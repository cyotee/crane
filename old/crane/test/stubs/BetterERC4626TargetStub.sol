// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterERC4626} from "contracts/crane/token/ERC20/extensions/BetterERC4626.sol";

// import {ERC4626Target} from "contracts/crane/token/ERC20/extensions/ERC4626Target.sol";
// import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";

/**
 * @title BetterERC4626TargetStub
 * @dev Test stub for BetterERC4626 with initialization for testing
 */
contract BetterERC4626TargetStub is BetterERC4626 {
    /**
     * @dev Constructor that initializes the ERC4626 vault
     * @param asset_ The address of the underlying asset
     * @param name_ The name of the vault token
     * @param symbol_ The symbol of the vault token
     * @param decimalsOffset_ The decimals offset for the vault
     */
    constructor(address asset_, string memory name_, string memory symbol_, uint8 decimalsOffset_)
        BetterERC4626(asset_, name_, symbol_, decimalsOffset_)
    {}
}
