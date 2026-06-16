// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {RedstonePrimaryProdWithoutRoundsERC7412} from "../erc7412/RedstonePrimaryProdWithoutRoundsERC7412.sol";
import {
    AuthorisedMockSignersBase
} from "@crane/contracts/external/redstone/packages/evm-connector/contracts/mocks/AuthorisedMockSignersBase.sol";

contract RedstonePrimaryProdERC7412Mock is RedstonePrimaryProdWithoutRoundsERC7412, AuthorisedMockSignersBase {
    function getDataFeedId() public pure override returns (bytes32) {
        return bytes32("BTC");
    }

    function getTTL() internal view virtual override returns (uint256) {
        return 60;
    }

    function getUniqueSignersThreshold() public view virtual override returns (uint8) {
        return 2;
    }

    function getAuthorisedSignerIndex(address signerAddress) public view virtual override returns (uint8) {
        return getAuthorisedMockSignerIndex(signerAddress);
    }
}
