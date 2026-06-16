pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapERC20.sol";

contract ERC20CoreTest is FraxswapERC20 {
    constructor(uint256 _totalSupply) {
        _mint(msg.sender, _totalSupply);
    }
}
