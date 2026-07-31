// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_UniswapV3Periphery
} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/test/bases/TestBase_UniswapV3Periphery.sol";
import {ISwapRouter} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from
    "@crane/contracts/protocols/dexes/uniswap/v3/periphery/interfaces/INonfungiblePositionManager.sol";
import {PonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/PonsLaunchFactory.sol";
import {PonsLauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/PonsLauncherToken.sol";
import {IPonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/interfaces/ILaunchpad.sol";
import {PonsLaunchLockerStub} from
    "@crane/contracts/protocols/launchpads/ponsFamily/stubs/PonsLaunchLockerStub.sol";

/// @title TestBase_PonsFamily
/// @notice Hermetic setup: real Uni V3 periphery + real PonsLaunchFactory + minimal locker stub.
abstract contract TestBase_PonsFamily is TestBase_UniswapV3Periphery {
    /* -------------------------------------------------------------------------- */
    /*                         Live-aligned hermetic defaults                     */
    /* -------------------------------------------------------------------------- */

    uint256 internal constant PONS_LAUNCH_FEE = 0.0005 ether;
    uint256 internal constant PONS_SUPPLY = 1_000_000_000 ether;
    uint256 internal constant PONS_GRADUATION_THRESHOLD = 4.2 ether;
    int24 internal constant PONS_INITIAL_TICK = -204_200;
    uint16 internal constant PONS_MAX_WALLET_BPS = 500;
    uint16 internal constant PONS_MAX_TX_BPS = 550;
    uint32 internal constant PONS_RESTRICTION_BLOCKS = 2;
    uint24 internal constant PONS_POOL_FEE = 10_000;
    int24 internal constant PONS_TICK_SPACING = 200;

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    PonsLaunchFactory internal ponsFactory;
    PonsLaunchLockerStub internal ponsLocker;
    address internal ponsOwner;
    address internal ponsFeeSink;
    address internal ponsLauncher;

    uint256 internal ponsDexId;
    uint256 internal ponsLaunchConfigId;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual override {
        TestBase_UniswapV3Periphery.setUp();

        if (address(ponsFactory) == address(0)) {
            ponsOwner = makeAddr("ponsOwner");
            ponsFeeSink = makeAddr("ponsFeeSink");
            ponsLauncher = makeAddr("ponsLauncher");

            ponsLocker = new PonsLaunchLockerStub(ponsFeeSink);
            vm.label(address(ponsLocker), "ponsLocker");

            vm.prank(ponsOwner);
            ponsFactory = new PonsLaunchFactory(ponsOwner, address(ponsLocker), PONS_LAUNCH_FEE);
            vm.label(address(ponsFactory), "ponsFactory");

            vm.startPrank(ponsOwner);
            ponsDexId = ponsFactory.addDexConfig(
                PonsLaunchFactory.DexConfig({
                    name: "uniswap v3",
                    factory: address(uniswapV3Factory),
                    positionManager: address(positionManager),
                    swapRouter: address(swapRouter),
                    poolFee: PONS_POOL_FEE,
                    tickSpacing: PONS_TICK_SPACING,
                    enabled: true
                })
            );
            ponsLaunchConfigId = ponsFactory.addLaunchConfig(
                PonsLaunchFactory.LaunchConfig({
                    pairToken: address(weth),
                    graduationThreshold: PONS_GRADUATION_THRESHOLD,
                    initialTick: PONS_INITIAL_TICK,
                    supply: PONS_SUPPLY,
                    maxWalletBps: PONS_MAX_WALLET_BPS,
                    maxTxBps: PONS_MAX_TX_BPS,
                    restrictionBlocks: PONS_RESTRICTION_BLOCKS,
                    reservedFee: 0,
                    enabled: true,
                    // Hermetic: Crane classic SwapRouter requires deadline.
                    routerRequiresDeadline: true
                })
            );
            ponsFactory.setLaunchEnabled(true);
            vm.stopPrank();

            vm.deal(ponsLauncher, 100 ether);
            vm.deal(address(this), 100 ether);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Helpers                                   */
    /* -------------------------------------------------------------------------- */

    function _defaultTokenParams(string memory name_, string memory symbol_)
        internal
        pure
        returns (PonsLaunchFactory.TokenParams memory)
    {
        return PonsLaunchFactory.TokenParams({
            name: name_,
            symbol: symbol_,
            logo: "ipfs://logo",
            description: "hermetic pons launch",
            socials: PonsLaunchFactory.Socials({
                twitter: "https://x.com/pons",
                telegram: "",
                discord: "",
                website: "https://pons.family",
                farcaster: ""
            }),
            feeWallet: address(0)
        });
    }

    function _defaultTokenParams() internal pure returns (PonsLaunchFactory.TokenParams memory) {
        return _defaultTokenParams("Pons Hermetic", "PHRM");
    }

    /// @dev Launch as `ponsLauncher` with vanity salt search start.
    function _launch(PonsLaunchFactory.TokenParams memory params, bytes32 saltStart, uint256 value)
        internal
        returns (address token)
    {
        vm.prank(ponsLauncher);
        token = ponsFactory.launchToken{value: value}(params, ponsLaunchConfigId, ponsDexId, saltStart);
    }

    function _launchWithoutSeed(PonsLaunchFactory.TokenParams memory params, bytes32 saltStart)
        internal
        returns (address token)
    {
        return _launch(params, saltStart, PONS_LAUNCH_FEE);
    }

    function _launchWithoutSeed(bytes32 saltStart) internal returns (address token) {
        return _launchWithoutSeed(_defaultTokenParams(), saltStart);
    }

    function _warpPastRestrictions(address token) internal {
        uint256 end = PonsLauncherToken(token).restrictionEndBlock();
        if (block.number <= end) {
            vm.roll(end + 1);
        }
    }

    /// @dev Buy tokens with native ETH via classic SwapRouter (wraps WETH when value is sent).
    function _buyTokensWithEth(address token, address buyer, uint256 ethIn)
        internal
        returns (uint256 amountOut)
    {
        vm.deal(buyer, buyer.balance + ethIn);
        vm.startPrank(buyer);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(weth),
            tokenOut: token,
            fee: PONS_POOL_FEE,
            recipient: buyer,
            deadline: block.timestamp + 1 hours,
            amountIn: ethIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        amountOut = swapRouter.exactInputSingle{value: ethIn}(params);
        vm.stopPrank();
    }

    function _positionOwner(uint256 positionId) internal view returns (address) {
        return INonfungiblePositionManager(address(positionManager)).ownerOf(positionId);
    }

    function _launched(address token) internal view returns (IPonsLaunchFactory.LaunchedToken memory) {
        return ponsFactory.getLaunchedToken(token);
    }
}
