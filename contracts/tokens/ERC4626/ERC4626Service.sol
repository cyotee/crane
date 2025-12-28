// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {Permit2AwareRepo} from "@crane/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol";
import {ERC4626Repo} from "@crane/contracts/tokens/ERC4626/ERC4626Repo.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {IERC4626Errors} from "@crane/contracts/interfaces/IERC4626Errors.sol";

library ERC4626Service {
    using BetterSafeERC20 for IERC20;

    function _secureReserveDeposit(
        ERC4626Repo.Storage storage layout,
        uint256 lastTotalAssets,
        uint256 amountTokenToDeposit
        // bool pretransfered
    )
        internal
        returns (uint256 actualIn)
    {
        IERC20 tokenIn = ERC4626Repo._reserveAsset(layout);
        uint256 currentBalance = tokenIn.balanceOf(address(this));
        actualIn = currentBalance - lastTotalAssets;
        if (actualIn != amountTokenToDeposit) {
            uint256 erc20Allowance = tokenIn.allowance(msg.sender, address(this));
            if (erc20Allowance < amountTokenToDeposit) {
                Permit2AwareRepo._permit2()
                    .transferFrom(msg.sender, address(this), uint160(amountTokenToDeposit), address(tokenIn));
            } else {
                tokenIn.safeTransferFrom(address(msg.sender), address(this), amountTokenToDeposit);
            }
            currentBalance = tokenIn.balanceOf(address(this));
            actualIn = currentBalance - lastTotalAssets;
        }
        if (actualIn != amountTokenToDeposit) {
            revert IERC4626Errors.ERC4626TransferNotReceived(amountTokenToDeposit, actualIn);
        }
        ERC4626Repo._setLastTotalAssets(layout, currentBalance);
    }

    function _secureReserveDeposit(
        uint256 lastTotalAssets,
        uint256 amountTokenToDeposit
        // bool pretransfered
    )
        internal
        returns (uint256 actualIn)
    {
        return _secureReserveDeposit(ERC4626Repo._layout(), lastTotalAssets, amountTokenToDeposit);
    }

    function _secureReserveDeposit(
        ERC4626Repo.Storage storage layout,
        uint256 amountTokenToDeposit
        // bool pretransfered
    )
        internal
        returns (uint256 actualIn)
    {
        return _secureReserveDeposit(layout, ERC4626Repo._lastTotalAssets(layout), amountTokenToDeposit);
    }

    function _secureReserveDeposit(
        uint256 amountTokenToDeposit
        // bool pretransfered
    )
        internal
        returns (uint256 actualIn)
    {
        return _secureReserveDeposit(ERC4626Repo._layout(), amountTokenToDeposit);
    }
}
