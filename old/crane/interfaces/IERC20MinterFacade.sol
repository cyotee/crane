// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20MintBurn} from "./IERC20MintBurn.sol";

interface IERC20MinterFacade {
    function maxMintAmount() external view returns (uint256);

    function setMaxMintAmount(uint256 maxMintAmount) external returns (bool result);

    function mint(IERC20MintBurn token, address to, uint256 amount) external returns (uint256 actual);
}
