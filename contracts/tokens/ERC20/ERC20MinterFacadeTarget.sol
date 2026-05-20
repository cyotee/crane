// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20MintBurn} from "@crane/contracts/interfaces/IERC20MintBurn.sol";
import {IERC20MinterFacade} from "@crane/contracts/tokens/ERC20/IERC20MinterFacade.sol";
import {ERC20MinterFacadeRepo} from "@crane/contracts/tokens/ERC20/ERC20MinterFacadeRepo.sol";

contract ERC20MinterFacadeTarget is IERC20MinterFacade {
    using ERC20MinterFacadeRepo for ERC20MinterFacadeRepo.Storage;

    function mintToken(IERC20MintBurn token, uint256 amount, address recipient) public returns (bool) {
        ERC20MinterFacadeRepo.Storage storage layoutStruct = ERC20MinterFacadeRepo._layoutStruct();
        uint256 lastMintTimestamp = layoutStruct._lastMintTimestamp(address(token));
        uint256 minMintInterval = layoutStruct._minMintInterval();
        if (block.timestamp < lastMintTimestamp + minMintInterval) {
            revert IERC20MinterFacade.MinimumMintInternalNotMet(lastMintTimestamp, block.timestamp, minMintInterval);
        }
        uint256 maxMintAmount = layoutStruct._maxMintAmount();
        if (amount > maxMintAmount) {
            amount = maxMintAmount;
        }
        layoutStruct._setLastMintTimestamp(recipient, block.timestamp);
        token.mint(recipient, amount);
        return true;
    }
}
