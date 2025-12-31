// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {TestBase_ERC4626} from "@crane/contracts/tokens/ERC4626/TestBase_ERC4626.sol";
import {ERC4626TargetStubHandler} from "@crane/contracts/tokens/ERC4626/ERC4626TargetStubHandler.sol";
import {ERC4626TargetStub} from "@crane/contracts/tokens/ERC4626/ERC4626TargetStub.sol";
import {ERC20PermitStub} from "@crane/contracts/tokens/ERC20/ERC20PermitStub.sol";
import {BetterPermit2} from "@crane/contracts/protocols/utils/permit2/BetterPermit2.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

/**
 * @title ERC4626Invariant_Test
 * @notice Invariant tests for ERC4626TargetStub implementation
 */
contract ERC4626Invariant_Test is TestBase_ERC4626 {
    uint256 constant INITIAL_ASSET_SUPPLY = 1_000_000_000e18;
    uint8 constant DECIMAL_OFFSET = 3;

    function _deployVault(ERC4626TargetStubHandler handler_) internal override returns (IERC4626 vault_) {
        // Deploy permit2
        IPermit2 permit2 = IPermit2(address(new BetterPermit2()));

        // Deploy reserve asset and mint to handler
        ERC20PermitStub reserveAsset =
            new ERC20PermitStub("Test Reserve", "TRES", 18, address(handler_), INITIAL_ASSET_SUPPLY);

        // Deploy vault
        vault_ = IERC4626(address(new ERC4626TargetStub(IERC20Metadata(address(reserveAsset)), DECIMAL_OFFSET, permit2)));
    }
}
