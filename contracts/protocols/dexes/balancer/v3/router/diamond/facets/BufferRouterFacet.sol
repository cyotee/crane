// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IBufferRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBufferRouter.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                            BufferRouterFacet                               */
/* -------------------------------------------------------------------------- */

/**
 * @title BufferRouterFacet
 * @notice Handles ERC4626 buffer operations for the Balancer V3 Router Diamond.
 * @dev Implements IBufferRouter interface for buffer initialization and liquidity.
 *
 * Key operations:
 * - Initialize buffers with underlying + wrapped tokens
 * - Add liquidity to existing buffers
 * - Query operations for simulating buffer actions
 */
contract BufferRouterFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(BufferRouterFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IBufferRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](10);
        funcs[0] = this.initializeBuffer.selector;
        funcs[1] = this.addLiquidityToBuffer.selector;
        funcs[2] = this.queryInitializeBuffer.selector;
        funcs[3] = this.queryAddLiquidityToBuffer.selector;
        funcs[4] = this.queryRemoveLiquidityFromBuffer.selector;
        funcs[5] = this.initializeBufferHook.selector;
        funcs[6] = this.addLiquidityToBufferHook.selector;
        funcs[7] = this.queryInitializeBufferHook.selector;
        funcs[8] = this.queryAddLiquidityToBufferHook.selector;
        funcs[9] = this.queryRemoveLiquidityFromBufferHook.selector;
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
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Initialize a vault buffer with underlying and wrapped tokens.
     * @param wrappedToken The ERC4626 wrapped token
     * @param exactAmountUnderlyingIn Amount of underlying tokens to deposit
     * @param exactAmountWrappedIn Amount of wrapped tokens to deposit
     * @param minIssuedShares Minimum shares to receive
     * @return issuedShares Amount of buffer shares issued
     */
    function initializeBuffer(
        IERC4626 wrappedToken,
        uint256 exactAmountUnderlyingIn,
        uint256 exactAmountWrappedIn,
        uint256 minIssuedShares
    ) external returns (uint256 issuedShares) {
        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(
                this.initializeBufferHook,
                (wrappedToken, exactAmountUnderlyingIn, exactAmountWrappedIn, minIssuedShares, msg.sender)
            )
        );
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Add liquidity to an existing vault buffer.
     * @param wrappedToken The ERC4626 wrapped token
     * @param maxAmountUnderlyingIn Maximum underlying tokens to add
     * @param maxAmountWrappedIn Maximum wrapped tokens to add
     * @param exactSharesToIssue Exact shares to issue
     * @return amountUnderlyingIn Actual underlying tokens deposited
     * @return amountWrappedIn Actual wrapped tokens deposited
     */
    function addLiquidityToBuffer(
        IERC4626 wrappedToken,
        uint256 maxAmountUnderlyingIn,
        uint256 maxAmountWrappedIn,
        uint256 exactSharesToIssue
    ) external returns (uint256 amountUnderlyingIn, uint256 amountWrappedIn) {
        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(
                this.addLiquidityToBufferHook,
                (wrappedToken, maxAmountUnderlyingIn, maxAmountWrappedIn, exactSharesToIssue, msg.sender)
            )
        );
        return abi.decode(result, (uint256, uint256));
    }

    /**
     * @notice Query initialization of a buffer (simulation).
     */
    function queryInitializeBuffer(
        IERC4626 wrappedToken,
        uint256 exactAmountUnderlyingIn,
        uint256 exactAmountWrappedIn
    ) external returns (uint256 issuedShares) {
        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(
                this.queryInitializeBufferHook,
                (wrappedToken, exactAmountUnderlyingIn, exactAmountWrappedIn)
            )
        );
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Query adding liquidity to a buffer (simulation).
     */
    function queryAddLiquidityToBuffer(
        IERC4626 wrappedToken,
        uint256 exactSharesToIssue
    ) external returns (uint256 amountUnderlyingIn, uint256 amountWrappedIn) {
        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.queryAddLiquidityToBufferHook, (wrappedToken, exactSharesToIssue))
        );
        return abi.decode(result, (uint256, uint256));
    }

    /**
     * @notice Query removing liquidity from a buffer (simulation).
     */
    function queryRemoveLiquidityFromBuffer(
        IERC4626 wrappedToken,
        uint256 exactSharesToRemove
    ) external returns (uint256 removedUnderlyingBalanceOut, uint256 removedWrappedBalanceOut) {
        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.queryRemoveLiquidityFromBufferHook, (wrappedToken, exactSharesToRemove))
        );
        return abi.decode(result, (uint256, uint256));
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    /**
     * @notice Hook for initializing a vault buffer.
     * @dev Can only be called by the Vault.
     */
    function initializeBufferHook(
        IERC4626 wrappedToken,
        uint256 exactAmountUnderlyingIn,
        uint256 exactAmountWrappedIn,
        uint256 minIssuedShares,
        address sharesOwner
    ) external nonReentrant onlyVault returns (uint256 issuedShares) {
        IVault vault = BalancerV3RouterStorageRepo._vault();

        issuedShares = vault.initializeBuffer(
            wrappedToken,
            exactAmountUnderlyingIn,
            exactAmountWrappedIn,
            minIssuedShares,
            sharesOwner
        );

        address asset = vault.getERC4626BufferAsset(wrappedToken);
        _takeTokenIn(sharesOwner, IERC20(asset), exactAmountUnderlyingIn, false);
        _takeTokenIn(sharesOwner, IERC20(address(wrappedToken)), exactAmountWrappedIn, false);
    }

    /**
     * @notice Hook for adding liquidity to vault buffers.
     * @dev Can only be called by the Vault.
     */
    function addLiquidityToBufferHook(
        IERC4626 wrappedToken,
        uint256 maxAmountUnderlyingIn,
        uint256 maxAmountWrappedIn,
        uint256 exactSharesToIssue,
        address sharesOwner
    ) external nonReentrant onlyVault returns (uint256 amountUnderlyingIn, uint256 amountWrappedIn) {
        IVault vault = BalancerV3RouterStorageRepo._vault();

        (amountUnderlyingIn, amountWrappedIn) = vault.addLiquidityToBuffer(
            wrappedToken,
            maxAmountUnderlyingIn,
            maxAmountWrappedIn,
            exactSharesToIssue,
            sharesOwner
        );

        address asset = vault.getERC4626BufferAsset(wrappedToken);
        _takeTokenIn(sharesOwner, IERC20(asset), amountUnderlyingIn, false);
        _takeTokenIn(sharesOwner, IERC20(address(wrappedToken)), amountWrappedIn, false);
    }

    /**
     * @notice Query hook for buffer initialization.
     * @dev Can only be called by the Vault.
     */
    function queryInitializeBufferHook(
        IERC4626 wrappedToken,
        uint256 exactAmountUnderlyingIn,
        uint256 exactAmountWrappedIn
    ) external nonReentrant onlyVault returns (uint256 issuedShares) {
        issuedShares = BalancerV3RouterStorageRepo._vault().initializeBuffer(
            wrappedToken,
            exactAmountUnderlyingIn,
            exactAmountWrappedIn,
            0,
            address(this)
        );
    }

    /**
     * @notice Query hook for adding liquidity to buffer.
     * @dev Can only be called by the Vault.
     */
    function queryAddLiquidityToBufferHook(
        IERC4626 wrappedToken,
        uint256 exactSharesToIssue
    ) external nonReentrant onlyVault returns (uint256 amountUnderlyingIn, uint256 amountWrappedIn) {
        (amountUnderlyingIn, amountWrappedIn) = BalancerV3RouterStorageRepo._vault().addLiquidityToBuffer(
            wrappedToken,
            type(uint128).max,
            type(uint128).max,
            exactSharesToIssue,
            address(this)
        );
    }

    /**
     * @notice Query hook for removing liquidity from buffer.
     * @dev Can only be called by the Vault.
     */
    function queryRemoveLiquidityFromBufferHook(
        IERC4626 wrappedToken,
        uint256 exactSharesToRemove
    ) external nonReentrant onlyVault returns (uint256 removedUnderlyingBalanceOut, uint256 removedWrappedBalanceOut) {
        return BalancerV3RouterStorageRepo._vault().removeLiquidityFromBuffer(wrappedToken, exactSharesToRemove, 0, 0);
    }
}
