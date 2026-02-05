// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouter.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/RouterTypes.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                         RouterAddLiquidityFacet                            */
/* -------------------------------------------------------------------------- */

/**
 * @title RouterAddLiquidityFacet
 * @notice Handles add liquidity operations for the Balancer V3 Router Diamond.
 * @dev Implements add liquidity functions from IRouter interface.
 */
contract RouterAddLiquidityFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(RouterAddLiquidityFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](11);
        // Add liquidity functions
        funcs[0] = this.addLiquidityProportional.selector;
        funcs[1] = this.queryAddLiquidityProportional.selector;
        funcs[2] = this.addLiquidityUnbalanced.selector;
        funcs[3] = this.queryAddLiquidityUnbalanced.selector;
        funcs[4] = this.addLiquiditySingleTokenExactOut.selector;
        funcs[5] = this.queryAddLiquiditySingleTokenExactOut.selector;
        funcs[6] = this.donate.selector;
        funcs[7] = this.addLiquidityCustom.selector;
        funcs[8] = this.queryAddLiquidityCustom.selector;
        // Hook functions
        funcs[9] = this.addLiquidityHook.selector;
        funcs[10] = this.queryAddLiquidityHook.selector;
    }

    /// @inheritdoc IFacet
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    /* ========================================================================== */
    /*                           ADD LIQUIDITY FUNCTIONS                          */
    /* ========================================================================== */

    function addLiquidityProportional(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256[] memory amountsIn) {
        bytes memory result = _unlockAndCall(
            msg.sender, pool, maxAmountsIn, exactBptAmountOut,
            AddLiquidityKind.PROPORTIONAL, wethIsEth, userData
        );
        (amountsIn, , ) = abi.decode(result, (uint256[], uint256, bytes));
    }

    function queryAddLiquidityProportional(
        address pool,
        uint256 exactBptAmountOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256[] memory amountsIn) {
        bytes memory result = _quoteAndCall(
            pool, _maxTokenLimits(pool), exactBptAmountOut,
            AddLiquidityKind.PROPORTIONAL, userData
        );
        (amountsIn, , ) = abi.decode(result, (uint256[], uint256, bytes));
    }

    function addLiquidityUnbalanced(
        address pool,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256 bptAmountOut) {
        bytes memory result = _unlockAndCall(
            msg.sender, pool, exactAmountsIn, minBptAmountOut,
            AddLiquidityKind.UNBALANCED, wethIsEth, userData
        );
        (, bptAmountOut, ) = abi.decode(result, (uint256[], uint256, bytes));
    }

    function queryAddLiquidityUnbalanced(
        address pool,
        uint256[] memory exactAmountsIn,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256 bptAmountOut) {
        bytes memory result = _quoteAndCall(
            pool, exactAmountsIn, 0,
            AddLiquidityKind.UNBALANCED, userData
        );
        (, bptAmountOut, ) = abi.decode(result, (uint256[], uint256, bytes));
    }

    function addLiquiditySingleTokenExactOut(
        address pool,
        IERC20 tokenIn,
        uint256 maxAmountIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256 amountIn) {
        (uint256[] memory maxAmountsIn, uint256 tokenIndex) = _getSingleInputArrayAndTokenIndex(
            pool, tokenIn, maxAmountIn
        );
        bytes memory result = _unlockAndCall(
            msg.sender, pool, maxAmountsIn, exactBptAmountOut,
            AddLiquidityKind.SINGLE_TOKEN_EXACT_OUT, wethIsEth, userData
        );
        (uint256[] memory amountsIn, , ) = abi.decode(result, (uint256[], uint256, bytes));
        return amountsIn[tokenIndex];
    }

    function queryAddLiquiditySingleTokenExactOut(
        address pool,
        IERC20 tokenIn,
        uint256 exactBptAmountOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256 amountIn) {
        (uint256[] memory maxAmountsIn, uint256 tokenIndex) = _getSingleInputArrayAndTokenIndex(
            pool, tokenIn, BalancerV3RouterStorageRepo.MAX_AMOUNT
        );
        bytes memory result = _quoteAndCall(
            pool, maxAmountsIn, exactBptAmountOut,
            AddLiquidityKind.SINGLE_TOKEN_EXACT_OUT, userData
        );
        (uint256[] memory amountsIn, , ) = abi.decode(result, (uint256[], uint256, bytes));
        return amountsIn[tokenIndex];
    }

    function donate(
        address pool,
        uint256[] memory amountsIn,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) {
        _unlockAndCall(
            msg.sender, pool, amountsIn, 0,
            AddLiquidityKind.DONATION, wethIsEth, userData
        );
    }

    function addLiquidityCustom(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    )
        external
        payable
        saveSender(msg.sender)
        returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData)
    {
        bytes memory result = _unlockAndCall(
            msg.sender, pool, maxAmountsIn, minBptAmountOut,
            AddLiquidityKind.CUSTOM, wethIsEth, userData
        );
        return abi.decode(result, (uint256[], uint256, bytes));
    }

    function queryAddLiquidityCustom(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 minBptAmountOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData) {
        bytes memory result = _quoteAndCall(
            pool, maxAmountsIn, minBptAmountOut,
            AddLiquidityKind.CUSTOM, userData
        );
        return abi.decode(result, (uint256[], uint256, bytes));
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    function addLiquidityHook(
        AddLiquidityHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData)
    {
        return _addLiquidityHook(params);
    }

    function queryAddLiquidityHook(
        AddLiquidityHookParams calldata params
    ) external onlyVault returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData) {
        return _queryAddLiquidityHook(params);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _unlockAndCall(
        address sender,
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 minBptAmountOut,
        AddLiquidityKind kind,
        bool wethIsEth,
        bytes memory userData
    ) internal returns (bytes memory) {
        return BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(
                this.addLiquidityHook,
                AddLiquidityHookParams({
                    sender: sender,
                    pool: pool,
                    maxAmountsIn: maxAmountsIn,
                    minBptAmountOut: minBptAmountOut,
                    kind: kind,
                    wethIsEth: wethIsEth,
                    userData: userData
                })
            )
        );
    }

    function _quoteAndCall(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 minBptAmountOut,
        AddLiquidityKind kind,
        bytes memory userData
    ) internal returns (bytes memory) {
        return BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(
                this.queryAddLiquidityHook,
                AddLiquidityHookParams({
                    sender: address(this),
                    pool: pool,
                    maxAmountsIn: maxAmountsIn,
                    minBptAmountOut: minBptAmountOut,
                    kind: kind,
                    wethIsEth: false,
                    userData: userData
                })
            )
        );
    }

    function _addLiquidityHook(
        AddLiquidityHookParams calldata params
    ) internal returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        IWETH weth = BalancerV3RouterStorageRepo._weth();
        bool isPrepaid = BalancerV3RouterStorageRepo._isPrepaid();

        (amountsIn, bptAmountOut, returnData) = vault.addLiquidity(
            AddLiquidityParams({
                pool: params.pool,
                to: params.sender,
                maxAmountsIn: params.maxAmountsIn,
                minBptAmountOut: params.minBptAmountOut,
                kind: params.kind,
                userData: params.userData
            })
        );

        _processTokensIn(params, amountsIn, vault, weth, isPrepaid);
        _returnEth(params.sender);
    }

    function _processTokensIn(
        AddLiquidityHookParams calldata params,
        uint256[] memory amountsIn,
        IVault vault,
        IWETH weth,
        bool isPrepaid
    ) internal {
        IERC20[] memory tokens = vault.getPoolTokens(params.pool);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amountIn = amountsIn[i];

            if (amountIn == 0) continue;

            if (!isPrepaid || (params.wethIsEth && address(token) == address(weth))) {
                _takeTokenIn(params.sender, token, amountIn, params.wethIsEth);
            } else {
                uint256 amountInHint = params.maxAmountsIn[i];
                uint256 tokenInCredit = vault.settle(token, amountInHint);
                if (tokenInCredit < amountInHint) {
                    revert InsufficientPayment(token);
                }
                _sendTokenOut(params.sender, token, tokenInCredit - amountIn, false);
            }
        }
    }

    function _queryAddLiquidityHook(
        AddLiquidityHookParams calldata params
    ) internal returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData) {
        return BalancerV3RouterStorageRepo._vault().addLiquidity(
            AddLiquidityParams({
                pool: params.pool,
                to: params.sender,
                maxAmountsIn: params.maxAmountsIn,
                minBptAmountOut: params.minBptAmountOut,
                kind: params.kind,
                userData: params.userData
            })
        );
    }
}
