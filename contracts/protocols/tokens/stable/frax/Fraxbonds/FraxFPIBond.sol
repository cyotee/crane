//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@crane/contracts/external/uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./FraxFPIBondYield.sol";
import "./interface/IFPIControllerPool.sol";

contract FraxFPIBond is ERC20Permit {
    IERC20 public constant FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 public constant FPI = IERC20(0x5Ca135cB8527d76e932f34B5145575F9d8cbE08E);
    uint256 public immutable expiry;
    FraxFPIBondYield public immutable yieldToken;
    IFPIControllerPool public immutable controllerPool;
    uint256 public fraxPerBond;
    uint256 public fraxPerYieldToken;

    constructor(string memory _name, string memory _symbol, uint256 _expiry, IFPIControllerPool _controllerPool)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {
        expiry = _expiry;
        controllerPool = _controllerPool;
        yieldToken = new FraxFPIBondYield(string.concat(_name, " Yield"), string.concat(_symbol, "Y"));
    }

    function mint(address to, uint256 amount) external {
        TransferHelper.safeTransferFrom(address(FPI), msg.sender, address(this), amount);
        _mint(to, amount);
        yieldToken.mint(to, amount);
    }

    function expirySwap() external {
        if (block.timestamp < expiry) revert("Too soon");
        uint256 fpiBalance = FPI.balanceOf(address(this));
        TransferHelper.safeApprove(address(FPI), address(controllerPool), fpiBalance);
        controllerPool.redeemFPI(fpiBalance, 0); // min_frax_out is zero, the controllerPool only redeems when price is within peg bounds.
        uint256 fraxBalance = FRAX.balanceOf(address(this));
        if (fraxBalance >= totalSupply()) {
            fraxPerBond = 1e18;
            fraxPerYieldToken = fraxBalance / totalSupply();
        } else {
            fraxPerBond = fraxBalance / totalSupply();
        }
    }

    function redeem(address to, uint256 amount) external {
        if (fraxPerBond == 0) revert("Too soon");
        _burn(msg.sender, amount);
        TransferHelper.safeTransfer(address(FRAX), to, amount * fraxPerBond / 1e18);
    }

    function redeemYieldToken(address to, uint256 amount) external {
        if (fraxPerBond == 0) revert("Too soon");
        yieldToken.burnFrom(msg.sender, amount);
        TransferHelper.safeTransfer(address(FRAX), to, amount * fraxPerYieldToken / 1e18);
    }
}
