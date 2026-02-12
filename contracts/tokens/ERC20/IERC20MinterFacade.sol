// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20MintBurn} from "@crane/contracts/interfaces/IERC20MintBurn.sol";

interface IERC20MinterFacade {
    error MinimumMintInternalNotMet(uint256 lastMintTimestamp, uint256 currentTimestamp, uint256 minMintInterval);

    function mintToken(
        IERC20MintBurn token,
        uint256 amount,
        address recipient
    ) external returns(bool);
}