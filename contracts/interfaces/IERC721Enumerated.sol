// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC721Enumerated {
    function tokenIds() external view returns (uint256[] memory);

    function ownedIds(address owner) external view returns (uint256[] memory);

    function globalOperatorOf(address owner) external view returns (address);
}
