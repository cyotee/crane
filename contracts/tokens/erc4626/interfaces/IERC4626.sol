// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// import { IERC20 } from 'contracts/tokens/erc20/interfaces/IERC20.sol';

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

import {
    IERC20
} from "../../erc20/interfaces/IERC20.sol";

/**
 * @title ERC4626 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-4626
 */
interface IERC4626 is IERC20 {

    /* ------------------------------- EVENTS ------------------------------- */

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /* --------------------------------- ERRORS --------------------------------- */

    /**
     * @dev Attempted to deposit more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxDeposit(address receiver, uint256 assets, uint256 max);

    /**
     * @dev Attempted to mint more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxMint(address receiver, uint256 shares, uint256 max);

    /**
     * @dev Attempted to withdraw more assets than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxWithdraw(address owner, uint256 assets, uint256 max);

    /**
     * @dev Attempted to redeem more shares than the max amount for `receiver`.
     */
    error ERC4626ExceededMaxRedeem(address owner, uint256 shares, uint256 max);

    error ExpectedSharesNotMet(
        uint256 expected,
        uint256 actual
    );

    error ExpectedAssetsNotMet(
        uint256 expected,
        uint256 actual
    );

    /* ------------------------------ FUNCTIONS ----------------------------- */

    // tag::asset[]
    /**
     * @notice get the address of the base token used for vault accounting purposes
     * @return base token address
     * @custom:sig asset()
     */
    function asset() external view returns (address);
    // end::asset[]

    // tag::totalAssets[]
    /**
     * @notice get the total quantity of the base asset currently managed by the vault
     * @return total managed asset amount
     * @custom:sig totalAssets()
     */
    function totalAssets() external view returns (uint256);
    // end::totalAssets[]

    // tag::convertToShares[]
    /**
     * @notice calculate the quantity of shares received in exchange
     * @notice for a given quantity of assets, not accounting for slippage
     * @param assetAmount quantity of assets to convert
     * @return shareAmount quantity of shares calculated
     * @custom:sig convertToShares(uint256)
     */
    function convertToShares(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount);
    // end::convertToShares[]

    // tag::convertToAssets[]
    /**
     * @notice calculate the quantity of assets received in exchange
     * @notice for a given quantity of shares, not accounting for slippage
     * @param shareAmount quantity of shares to convert
     * @return assetAmount quantity of assets calculated
     * @custom:sig convertToAssets(uint256)
     */
    function convertToAssets(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount);
    // end::convertToAssets[]

    // tag::maxDeposit[]
    /**
     * @notice calculate the maximum quantity of base assets which may be deposited on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxAssets maximum asset deposit amount
     * @custom:sig maxDeposit(address)
     */
    function maxDeposit(
        address receiver
    ) external view returns (uint256 maxAssets);
    // end::maxDeposit[]

    // tag::maxMint[]
    /**
     * @notice calculate the maximum quantity of shares which may be minted on behalf of given receiver
     * @param receiver recipient of shares resulting from deposit
     * @return maxShares maximum share mint amount
     * @custom:sig maxMint(address)
     */
    function maxMint(
        address receiver
    ) external view returns (uint256 maxShares);
    // end::maxMint[]

    // tag::maxWithdraw[]
    /**
     * @notice calculate the maximum quantity of base assets which may be withdrawn by given holder
     * @param owner holder of shares to be redeemed
     * @return maxAssets maximum asset mint amount
     * @custom:sig maxWithdraw(address)
     */
    function maxWithdraw(
        address owner
    ) external view returns (uint256 maxAssets);
    // end::maxWithdraw[]

    // tag::maxRedeem[]
    /**
     * @notice calculate the maximum quantity of shares which may be redeemed by given holder
     * @param owner holder of shares to be redeemed
     * @return maxShares maximum share redeem amount
     * @custom:sig maxRedeem(address)
     */
    function maxRedeem(
        address owner
    ) external view returns (uint256 maxShares);
    // end::maxRedeem[]

    // tag::previewDeposit[]
    /**
     * @notice simulate a deposit of given quantity of assets
     * @param assetAmount quantity of assets to deposit
     * @return shareAmount quantity of shares to mint
     * @custom:sig previewDeposit(uint256)
     */
    function previewDeposit(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount);
    // end::previewDeposit[]

    // tag::previewMint[]
    /**
     * @notice simulate a minting of given quantity of shares
     * @param shareAmount quantity of shares to mint
     * @return assetAmount quantity of assets to deposit
     * @custom:sig previewMint(uint256)
     */
    function previewMint(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount);
    // end::previewMint[]

    // tag::previewWithdraw[]
    /**
     * @notice simulate a withdrawal of given quantity of assets
     * @param assetAmount quantity of assets to withdraw
     * @return shareAmount quantity of shares to redeem
     * @custom:sig previewWithdraw(uint256)
     */
    function previewWithdraw(
        uint256 assetAmount
    ) external view returns (uint256 shareAmount);
    // end::previewWithdraw[]

    // tag::previewRedeem[]
    /**
     * @notice simulate a redemption of given quantity of shares
     * @param shareAmount quantity of shares to redeem
     * @return assetAmount quantity of assets to withdraw
     * @custom:sig previewRedeem(uint256)
     */
    function previewRedeem(
        uint256 shareAmount
    ) external view returns (uint256 assetAmount);
    // end::previewRedeem[]

    // tag::deposit[]
    /**
     * @notice execute a deposit of assets on behalf of given address
     * @param assetAmount quantity of assets to deposit
     * @param receiver recipient of shares resulting from deposit
     * @return shareAmount quantity of shares to mint
     * @custom:sig deposit(uint256,address)
     * @custom:emits Deposit(address indexed,address indexed,uint256,uint256)
     */
    function deposit(
        uint256 assetAmount,
        address receiver
    ) external returns (uint256 shareAmount);
    // end::deposit[]

    // tag::mint[]
    /**
     * @notice execute a minting of shares on behalf of given address
     * @param shareAmount quantity of shares to mint
     * @param receiver recipient of shares resulting from deposit
     * @return assetAmount quantity of assets to deposit
     * @custom:sig mint(uint256,address)
     * @custom:emits Deposit(address indexed,address indexed,uint256,uint256)
     */
    function mint(
        uint256 shareAmount,
        address receiver
    ) external returns (uint256 assetAmount);
    // end::mint[]

    // tag::withdraw[]
    /**
     * @notice execute a withdrawal of assets on behalf of given address
     * @param assetAmount quantity of assets to withdraw
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return shareAmount quantity of shares to redeem
     * @custom:sig withdraw(uint256,address,address)
     * @custom:emits Withdraw(address indexed,address indexed,address indexed,uint256,uint256)
     */
    function withdraw(
        uint256 assetAmount,
        address receiver,
        address owner
    ) external returns(uint256 shareAmount);
    // end::withdraw[]

    // tag::redeem[]
    /**
     * @notice execute a redemption of shares on behalf of given address
     * @param shareAmount quantity of shares to redeem
     * @param receiver recipient of assets resulting from withdrawal
     * @param owner holder of shares to be redeemed
     * @return assetAmount quantity of assets to withdraw
     * @custom:sig redeem(uint256,address,address)
     * @custom:emits Withdraw(address indexed,address indexed,address indexed,uint256,uint256)
     */
    function redeem(
        uint256 shareAmount,
        address receiver,
        address owner
    ) external returns (uint256 assetAmount);
    // end::redeem[]

}
