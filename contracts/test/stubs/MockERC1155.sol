// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC1155} from "@crane/contracts/external/solady/tokens/ERC1155.sol";

/// @notice Simple mock ERC1155 for testing
contract MockERC1155 is ERC1155 {
    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount, "");
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }

    function uri(uint256) public pure override returns (string memory) {
        return "mock://";
    }
}
