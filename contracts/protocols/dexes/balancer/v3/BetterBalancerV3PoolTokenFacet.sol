// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { BetterERC20 } from "contracts/token/ERC20/BetterERC20.sol";
import { ERC20Storage } from "contracts/token/ERC20/utils/ERC20Storage.sol";
import {BetterERC20Permit} from "contracts/token/ERC20/extensions/BetterERC20Permit.sol";
import {IBalancerPoolToken} from "contracts/interfaces/IBalancerPoolToken.sol";
import {BetterBalancerV3PoolTokenStorage} from "./vault/utils/BetterBalancerV3PoolTokenStorage.sol";
import { VaultGaurdModifiers } from "./VaultGaurdModifiers.sol";
import {Create3AwareContract} from "contracts/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";

contract BetterBalancerV3PoolTokenFacet
is
    Create3AwareContract,
    BetterBalancerV3PoolTokenStorage,
    BetterERC20Permit,
    VaultGaurdModifiers,
    IBalancerPoolToken,
    IFacet
{

    constructor(CREATE3InitData memory create3InitData_)
    Create3AwareContract(create3InitData_){}

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](7);
        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IRateProvider).interfaceId;
        interfaces[6] = type(IBalancerPoolToken).interfaceId;
    }
    
    function facetFuncs()
    public pure virtual returns(bytes4[] memory funcs) {
        funcs = new bytes4[](16);

        funcs[0] = IERC20Metadata.name.selector;
        funcs[1] = IERC20Metadata.symbol.selector;
        funcs[2] = IERC20Metadata.decimals.selector;
        funcs[3] = IERC20.totalSupply.selector;
        funcs[4] = IERC20.balanceOf.selector;
        funcs[5] = IERC20.allowance.selector;
        funcs[6] = IERC20.approve.selector;
        funcs[7] = IERC20.transfer.selector;
        funcs[8] = IERC20.transferFrom.selector;

        funcs[9] = IERC5267.eip712Domain.selector;

        funcs[10] = IERC20Permit.permit.selector;
        funcs[11] = IERC20Permit.nonces.selector;
        funcs[12] = IERC20Permit.DOMAIN_SEPARATOR.selector;

        funcs[13] = IRateProvider.getRate.selector;
        funcs[14] = IBalancerPoolToken.emitTransfer.selector;
        funcs[15] = IBalancerPoolToken.emitApproval.selector;

    }
    
    // tag::transfer[]
    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override(BetterERC20, IERC20) returns (bool result) {
        _transfer(msg.sender, recipient, amount);
        // Emit the required event.
        // emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    // end::transfer[]

    // tag::transferFrom[]
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(BetterERC20, IERC20) returns (bool result) {
        _transferFrom(msg.sender, sender, recipient, amount);
        // Emit the required event.
        // emit Transfer(sender, recipient, amount);
        result = true;
    }
    // end::transferFrom[]

    function _decimals()
    internal view virtual
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage)
    returns (uint8 precision) {
        return BetterBalancerV3PoolTokenStorage._decimals();
    }

    function _totalSupply()
    internal view virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage)
    returns (uint256 supply) {
        return BetterBalancerV3PoolTokenStorage._totalSupply();
    }

    function _mint(
        uint256 , // amount,
        address , // account,
        uint256 // currentSupply
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _mint(
        address , // account,
        uint256 , // amount,
        uint256 // currentSupply
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _mint(
        uint256 , // amount,
        address // account
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _mint(
        address , // account,
        uint256 // amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {   
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        uint256 , // amount,
        address , // account,
        uint256 // currentSupply
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        address , // account,
        uint256 , // amount,
        uint256 // currentSupply
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }
    
    function _burn(
        address , // account,
        uint256 // amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _burn(
        uint256 , // amount,
        address // account
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }
    
    function _balanceOf(
        address account_
    ) internal view virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage)
    returns (uint256 balance) {
        return BetterBalancerV3PoolTokenStorage._balanceOf(account_);
    }

    function _increaseBalanceOf(
        address , // account,
        uint256 // amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _decreaseBalanceOf(
        address , // account,
        uint256 // amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        revert LocaclOperationNotAllowed();
    }

    function _allowance(
        address owner,
        address spender
    ) internal view virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage)
    returns (uint256) {
        return BetterBalancerV3PoolTokenStorage._allowance(owner, spender);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        BetterBalancerV3PoolTokenStorage._approve(owner, spender, amount);
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        BetterBalancerV3PoolTokenStorage._increaseAllowance(owner, spender, amount);
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        BetterBalancerV3PoolTokenStorage._decreaseAllowance(owner, spender, amount);
    }

    function _transfer(
        address owner,
        address recipient,
        uint256 amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        BetterBalancerV3PoolTokenStorage._transfer(owner, recipient, amount);
    }
    function _transferFrom(
        address spender,
        address owner,
        address recipient,
        uint256 amount
    ) internal virtual 
    override(ERC20Storage, BetterBalancerV3PoolTokenStorage) {
        BetterBalancerV3PoolTokenStorage._transferFrom(spender, owner, recipient, amount);
    }
    
    /// @dev Emit the Transfer event. This function can only be called by the MultiToken.
    function emitTransfer(address from, address to, uint256 amount) external onlyVault() {
        emit Transfer(from, to, amount);
    }

    /// @dev Emit the Approval event. This function can only be called by the MultiToken.
    function emitApproval(address owner, address spender, uint256 amount) external onlyVault() {
        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Get the BPT rate, which is defined as: pool invariant/total supply.
     * @dev The VaultExtension contract defines a default implementation (`getBptRate`) to calculate the rate
     * of any given pool, which should be sufficient in nearly all cases.
     *
     * @return rate Rate of the pool's BPT
     */
    function getRate() public view virtual returns (uint256) {
        return _balV3Vault().getBptRate(address(this));
    }

}