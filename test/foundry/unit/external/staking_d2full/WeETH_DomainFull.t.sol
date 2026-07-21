// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ERC1967Proxy} from "@crane/contracts/external/openzeppelin-contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {WeETH} from "@crane/contracts/external/etherfi/core/WeETH.sol";
import {IeETH} from "@crane/contracts/external/etherfi/core/interfaces/IeETH.sol";

/// @dev eETH mock with shares == balances for WeETH underbacking invariant.
contract MockEETH is ERC20, IeETH {
    constructor() ERC20("eETH", "eETH") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function name() public pure override(ERC20, IeETH) returns (string memory) {
        return "eETH";
    }

    function symbol() public pure override(ERC20, IeETH) returns (string memory) {
        return "eETH";
    }

    function decimals() public pure override(ERC20, IeETH) returns (uint8) {
        return 18;
    }

    function totalShares() external view returns (uint256) {
        return totalSupply();
    }

    function shares(address user) external view returns (uint256) {
        return balanceOf(user);
    }

    function balanceOf(address user) public view override(ERC20, IeETH) returns (uint256) {
        return super.balanceOf(user);
    }

    function transfer(address to, uint256 amount) public override(ERC20, IeETH) returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount)
        public
        override(ERC20, IeETH)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    function approve(address spender, uint256 amount) public override(ERC20, IeETH) returns (bool) {
        return super.approve(spender, amount);
    }

    function initialize() external {}

    function mintShares(address user, uint256 share) external {
        _mint(user, share);
    }

    function burnShares(address user, uint256 share) external {
        _burn(user, share);
    }

    function increaseAllowance(address spender, uint256 added) external returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + added);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subbed) external returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) - subbed);
        return true;
    }

    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external pure {}
}

contract MockLiquidityPool {
    function sharesForAmount(uint256 amount) external pure returns (uint256) {
        return amount;
    }

    function amountForShare(uint256 share) external pure returns (uint256) {
        return share;
    }
}

contract MockBlacklister {
    function blacklistUser(address) external pure {}
    function unblacklistUser(address) external pure {}
    function nonBlacklisted(address) external pure {}
}

/// @notice Domain wrap/unwrap against full vendored WeETH.
contract WeETH_DomainFullTest is Test {
    MockEETH internal eeth;
    MockLiquidityPool internal pool;
    MockBlacklister internal blacklister;
    WeETH internal weeth;

    function setUp() public {
        eeth = new MockEETH();
        pool = new MockLiquidityPool();
        blacklister = new MockBlacklister();
        WeETH impl = new WeETH(address(eeth), address(pool), address(0xBEEF), address(blacklister));
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), abi.encodeCall(WeETH.initialize, ()));
        weeth = WeETH(address(proxy));
    }

    function test_Domain_WeETH_BytecodePresent() public view {
        assertEq(address(weeth.eETH()), address(eeth));
        assertEq(address(weeth.liquidityPool()), address(pool));
    }

    function test_Domain_WrapUnwrap_Inverse() public {
        uint256 amount = 5 ether;
        eeth.mint(address(this), amount);
        eeth.approve(address(weeth), amount);

        uint256 weOut = weeth.wrap(amount);
        assertEq(weOut, amount, "1:1 wrap");
        assertEq(weeth.balanceOf(address(this)), amount);
        assertEq(eeth.balanceOf(address(weeth)), amount);

        uint256 eBack = weeth.unwrap(weOut);
        assertEq(eBack, amount);
        assertEq(eeth.balanceOf(address(this)), amount);
        assertEq(weeth.balanceOf(address(this)), 0);
    }

    function test_Domain_GetRate() public view {
        assertEq(weeth.getRate(), 1 ether);
    }
}
