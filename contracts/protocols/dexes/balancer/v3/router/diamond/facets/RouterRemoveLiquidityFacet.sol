// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouter.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/RouterTypes.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                       RouterRemoveLiquidityFacet                           */
/* -------------------------------------------------------------------------- */

/**
 * @title RouterRemoveLiquidityFacet
 * @notice Handles remove liquidity operations for the Balancer V3 Router Diamond.
 * @dev Implements remove liquidity functions from IRouter interface.
 */
contract RouterRemoveLiquidityFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(RouterRemoveLiquidityFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](12);
        // Remove liquidity functions
        funcs[0] = this.removeLiquidityProportional.selector;
        funcs[1] = this.queryRemoveLiquidityProportional.selector;
        funcs[2] = this.removeLiquiditySingleTokenExactIn.selector;
        funcs[3] = this.queryRemoveLiquiditySingleTokenExactIn.selector;
        funcs[4] = this.removeLiquiditySingleTokenExactOut.selector;
        funcs[5] = this.queryRemoveLiquiditySingleTokenExactOut.selector;
        funcs[6] = this.removeLiquidityCustom.selector;
        funcs[7] = this.queryRemoveLiquidityCustom.selector;
        funcs[8] = this.removeLiquidityRecovery.selector;
        funcs[9] = this.queryRemoveLiquidityRecovery.selector;
        // Hook functions
        funcs[10] = this.removeLiquidityHook.selector;
        funcs[11] = this.queryRemoveLiquidityHook.selector;
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
    /*                         REMOVE LIQUIDITY FUNCTIONS                         */
    /* ========================================================================== */

    function removeLiquidityProportional(
        address pool,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256[] memory amountsOut) {
        bytes memory result = _unlockRemove(
            msg.sender, pool, minAmountsOut, exactBptAmountIn,
            RemoveLiquidityKind.PROPORTIONAL, wethIsEth, userData
        );
        (, amountsOut, ) = abi.decode(result, (uint256, uint256[], bytes));
    }

    function queryRemoveLiquidityProportional(
        address pool,
        uint256 exactBptAmountIn,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        uint256[] memory minAmountsOut = new uint256[](vault.getPoolTokens(pool).length);
        bytes memory result = _quoteRemove(
            pool, minAmountsOut, exactBptAmountIn,
            RemoveLiquidityKind.PROPORTIONAL, userData
        );
        (, amountsOut, ) = abi.decode(result, (uint256, uint256[], bytes));
    }

    function removeLiquiditySingleTokenExactIn(
        address pool,
        uint256 exactBptAmountIn,
        IERC20 tokenOut,
        uint256 minAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256 amountOut) {
        (uint256[] memory minAmountsOut, uint256 tokenIndex) = _getSingleInputArrayAndTokenIndex(
            pool, tokenOut, minAmountOut
        );
        bytes memory result = _unlockRemove(
            msg.sender, pool, minAmountsOut, exactBptAmountIn,
            RemoveLiquidityKind.SINGLE_TOKEN_EXACT_IN, wethIsEth, userData
        );
        (, uint256[] memory amountsOut, ) = abi.decode(result, (uint256, uint256[], bytes));
        return amountsOut[tokenIndex];
    }

    function queryRemoveLiquiditySingleTokenExactIn(
        address pool,
        uint256 exactBptAmountIn,
        IERC20 tokenOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256 amountOut) {
        // We cannot use 0 as min amount, as this value is used to figure out the token index.
        (uint256[] memory minAmountsOut, uint256 tokenIndex) = _getSingleInputArrayAndTokenIndex(pool, tokenOut, 1);
        bytes memory result = _quoteRemove(
            pool, minAmountsOut, exactBptAmountIn,
            RemoveLiquidityKind.SINGLE_TOKEN_EXACT_IN, userData
        );
        (, uint256[] memory amountsOut, ) = abi.decode(result, (uint256, uint256[], bytes));
        return amountsOut[tokenIndex];
    }

    function removeLiquiditySingleTokenExactOut(
        address pool,
        uint256 maxBptAmountIn,
        IERC20 tokenOut,
        uint256 exactAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256 bptAmountIn) {
        (uint256[] memory minAmountsOut, ) = _getSingleInputArrayAndTokenIndex(pool, tokenOut, exactAmountOut);
        bytes memory result = _unlockRemove(
            msg.sender, pool, minAmountsOut, maxBptAmountIn,
            RemoveLiquidityKind.SINGLE_TOKEN_EXACT_OUT, wethIsEth, userData
        );
        (bptAmountIn, , ) = abi.decode(result, (uint256, uint256[], bytes));
    }

    function queryRemoveLiquiditySingleTokenExactOut(
        address pool,
        IERC20 tokenOut,
        uint256 exactAmountOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256 bptAmountIn) {
        (uint256[] memory minAmountsOut, ) = _getSingleInputArrayAndTokenIndex(pool, tokenOut, exactAmountOut);
        bytes memory result = _quoteRemove(
            pool, minAmountsOut, BalancerV3RouterStorageRepo.MAX_AMOUNT,
            RemoveLiquidityKind.SINGLE_TOKEN_EXACT_OUT, userData
        );
        (bptAmountIn, , ) = abi.decode(result, (uint256, uint256[], bytes));
    }

    function removeLiquidityCustom(
        address pool,
        uint256 maxBptAmountIn,
        uint256[] memory minAmountsOut,
        bool wethIsEth,
        bytes memory userData
    )
        external
        payable
        saveSender(msg.sender)
        returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData)
    {
        bytes memory result = _unlockRemove(
            msg.sender, pool, minAmountsOut, maxBptAmountIn,
            RemoveLiquidityKind.CUSTOM, wethIsEth, userData
        );
        return abi.decode(result, (uint256, uint256[], bytes));
    }

    function queryRemoveLiquidityCustom(
        address pool,
        uint256 maxBptAmountIn,
        uint256[] memory minAmountsOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData) {
        bytes memory result = _quoteRemove(
            pool, minAmountsOut, maxBptAmountIn,
            RemoveLiquidityKind.CUSTOM, userData
        );
        return abi.decode(result, (uint256, uint256[], bytes));
    }

    function removeLiquidityRecovery(
        address pool,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut
    ) external payable returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        amountsOut = abi.decode(
            vault.unlock(
                abi.encodeCall(
                    this.removeLiquidityRecoveryHook,
                    (pool, msg.sender, exactBptAmountIn, minAmountsOut)
                )
            ),
            (uint256[])
        );
    }

    function queryRemoveLiquidityRecovery(
        address pool,
        uint256 exactBptAmountIn
    ) external returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        return abi.decode(
            vault.quote(
                abi.encodeCall(
                    this.queryRemoveLiquidityRecoveryHook,
                    (pool, address(this), exactBptAmountIn)
                )
            ),
            (uint256[])
        );
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    function removeLiquidityHook(
        RemoveLiquidityHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData)
    {
        return _removeLiquidityHook(params);
    }

    function queryRemoveLiquidityHook(
        RemoveLiquidityHookParams calldata params
    ) external onlyVault returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData) {
        return _queryRemoveLiquidityHook(params);
    }

    function removeLiquidityRecoveryHook(
        address pool,
        address sender,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut
    ) external nonReentrant onlyVault returns (uint256[] memory amountsOut) {
        return _removeLiquidityRecoveryHook(pool, sender, exactBptAmountIn, minAmountsOut);
    }

    function queryRemoveLiquidityRecoveryHook(
        address pool,
        address sender,
        uint256 exactBptAmountIn
    ) external onlyVault returns (uint256[] memory amountsOut) {
        return _queryRemoveLiquidityRecoveryHook(pool, sender, exactBptAmountIn);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _unlockRemove(
        address sender,
        address pool,
        uint256[] memory minAmountsOut,
        uint256 maxBptAmountIn,
        RemoveLiquidityKind kind,
        bool wethIsEth,
        bytes memory userData
    ) internal returns (bytes memory) {
        return BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(
                this.removeLiquidityHook,
                RemoveLiquidityHookParams({
                    sender: sender,
                    pool: pool,
                    minAmountsOut: minAmountsOut,
                    maxBptAmountIn: maxBptAmountIn,
                    kind: kind,
                    wethIsEth: wethIsEth,
                    userData: userData
                })
            )
        );
    }

    function _quoteRemove(
        address pool,
        uint256[] memory minAmountsOut,
        uint256 maxBptAmountIn,
        RemoveLiquidityKind kind,
        bytes memory userData
    ) internal returns (bytes memory) {
        return BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(
                this.queryRemoveLiquidityHook,
                RemoveLiquidityHookParams({
                    sender: address(this),
                    pool: pool,
                    minAmountsOut: minAmountsOut,
                    maxBptAmountIn: maxBptAmountIn,
                    kind: kind,
                    wethIsEth: false,
                    userData: userData
                })
            )
        );
    }

    function _removeLiquidityHook(
        RemoveLiquidityHookParams calldata params
    ) internal returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData) {
        IVault vault = BalancerV3RouterStorageRepo._vault();

        (bptAmountIn, amountsOut, returnData) = vault.removeLiquidity(
            RemoveLiquidityParams({
                pool: params.pool,
                from: params.sender,
                maxBptAmountIn: params.maxBptAmountIn,
                minAmountsOut: params.minAmountsOut,
                kind: params.kind,
                userData: params.userData
            })
        );

        IERC20[] memory tokens = vault.getPoolTokens(params.pool);
        for (uint256 i = 0; i < tokens.length; ++i) {
            _sendTokenOut(params.sender, tokens[i], amountsOut[i], params.wethIsEth);
        }

        _returnEth(params.sender);
    }

    function _queryRemoveLiquidityHook(
        RemoveLiquidityHookParams calldata params
    ) internal returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData) {
        return BalancerV3RouterStorageRepo._vault().removeLiquidity(
            RemoveLiquidityParams({
                pool: params.pool,
                from: params.sender,
                maxBptAmountIn: params.maxBptAmountIn,
                minAmountsOut: params.minAmountsOut,
                kind: params.kind,
                userData: params.userData
            })
        );
    }

    function _removeLiquidityRecoveryHook(
        address pool,
        address sender,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut
    ) internal returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();

        amountsOut = vault.removeLiquidityRecovery(pool, sender, exactBptAmountIn, minAmountsOut);

        IERC20[] memory tokens = vault.getPoolTokens(pool);
        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amountOut = amountsOut[i];
            if (amountOut > 0) {
                vault.sendTo(tokens[i], sender, amountOut);
            }
        }

        _returnEth(sender);
    }

    function _queryRemoveLiquidityRecoveryHook(
        address pool,
        address sender,
        uint256 exactBptAmountIn
    ) internal returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        uint256[] memory minAmountsOut = new uint256[](vault.getPoolTokens(pool).length);
        return vault.removeLiquidityRecovery(pool, sender, exactBptAmountIn, minAmountsOut);
    }
}
