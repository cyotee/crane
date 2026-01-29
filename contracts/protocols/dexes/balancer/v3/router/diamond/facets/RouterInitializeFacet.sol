// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/RouterTypes.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                          RouterInitializeFacet                             */
/* -------------------------------------------------------------------------- */

/**
 * @title RouterInitializeFacet
 * @notice Handles pool initialization for the Balancer V3 Router Diamond.
 * @dev Implements the initialize function from IRouter interface.
 *
 * Pool initialization:
 * 1. External function saves sender and calls vault.unlock() with encoded hook params
 * 2. Vault calls back into initializeHook within transient context
 * 3. Hook calls vault.initialize() and handles token transfers
 * 4. BPT minted to sender
 */
contract RouterInitializeFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(RouterInitializeFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IRouter.initialize.selector;
        funcs[1] = this.initializeHook.selector;
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
    using SafeCast for uint256;

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Initializes a pool with the given tokens and amounts.
     * @param pool Pool address to initialize
     * @param tokens Array of tokens in the pool (must match pool registration order)
     * @param exactAmountsIn Exact amounts of each token to deposit
     * @param minBptAmountOut Minimum BPT to receive
     * @param wethIsEth Whether to treat WETH as ETH for wrapping
     * @param userData Additional data passed to the pool
     * @return bptAmountOut Amount of BPT minted
     */
    function initialize(
        address pool,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256 bptAmountOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();

        return abi.decode(
            vault.unlock(
                abi.encodeCall(
                    this.initializeHook,
                    InitializeHookParams({
                        sender: msg.sender,
                        pool: pool,
                        tokens: tokens,
                        exactAmountsIn: exactAmountsIn,
                        minBptAmountOut: minBptAmountOut,
                        wethIsEth: wethIsEth,
                        userData: userData
                    })
                )
            ),
            (uint256)
        );
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    /**
     * @notice Hook for pool initialization, called by the Vault during unlock.
     * @dev Can only be called by the Vault.
     * @param params Initialization parameters
     * @return bptAmountOut BPT amount minted
     */
    function initializeHook(
        InitializeHookParams calldata params
    ) external nonReentrant onlyVault returns (uint256 bptAmountOut) {
        return _initializeHook(params);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _initializeHook(InitializeHookParams calldata params) internal returns (uint256 bptAmountOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();

        bptAmountOut = vault.initialize(
            params.pool,
            params.sender,
            params.tokens,
            params.exactAmountsIn,
            params.minBptAmountOut,
            params.userData
        );

        for (uint256 i = 0; i < params.tokens.length; ++i) {
            _takeTokenIn(params.sender, params.tokens[i], params.exactAmountsIn[i], params.wethIsEth);
        }

        // Return excess ETH
        _returnEth(params.sender);
    }
}
