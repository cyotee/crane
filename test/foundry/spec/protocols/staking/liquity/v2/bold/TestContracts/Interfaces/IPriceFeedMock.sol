// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

import "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IPriceFeed.sol";

interface IPriceFeedMock is IPriceFeed {
    function setPrice(uint256 _price) external;
}
