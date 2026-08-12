// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_UniswapV3Periphery
} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/test/bases/TestBase_UniswapV3Periphery.sol";
import {ISwapRouter} from "@crane/contracts/protocols/dexes/uniswap/v3/periphery/interfaces/ISwapRouter.sol";
import {INonfungiblePositionManager} from
    "@crane/contracts/protocols/dexes/uniswap/v3/periphery/interfaces/INonfungiblePositionManager.sol";
import {PonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLaunchFactory.sol";
import {PonsLauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLauncherToken.sol";
import {PonsLaunchLocker} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/PonsLaunchLocker.sol";
import {IPonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v1/interfaces/ILaunchpad.sol";

/// @title TestBase_PonsFamily
/// @notice Hermetic setup: real Uni V3 periphery + real PonsLaunchFactory + production PonsLaunchLocker.
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
    /// @dev Matches current active-factory era (70/30 creator/protocol).
    uint256 internal constant PONS_PROTOCOL_FEE_SHARE = 30;

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    PonsLaunchFactory internal ponsFactory;
    PonsLaunchLocker internal ponsLocker;
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

            // Production locker: owner + protocol fee recipient + protocol share snapshot default.
            vm.prank(ponsOwner);
            ponsLocker = new PonsLaunchLocker(ponsOwner, ponsFeeSink, PONS_PROTOCOL_FEE_SHARE);
            vm.label(address(ponsLocker), "ponsLocker");

            vm.prank(ponsOwner);
            ponsFactory = new PonsLaunchFactory(ponsOwner, address(ponsLocker), PONS_LAUNCH_FEE);
            vm.label(address(ponsFactory), "ponsFactory");

            // Locker binds factory once after both are deployed (production pattern).
            vm.prank(ponsOwner);
            ponsLocker.initialize(address(ponsFactory));

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

    /// @dev Single-shot launch (used via external self-call for OOG isolation).
    function tryLaunchWithoutSeed(bytes32 saltStart) external returns (address token) {
        require(msg.sender == address(this), "only self");
        return _launchWithoutSeed(_defaultTokenParams(), saltStart);
    }

    /**
     * @dev Launch with default params. Retries alternate salt starts because vanity
     * suffix mining (`0xbbbb`) can MemoryOOG on a single 1e6-step search when
     * creation bytecode is large (default optimizer_runs=1). Each attempt is an
     * external self-call so an OOG attempt does not fail the whole test.
     */
    function _launchWithoutSeed(bytes32 saltHint) internal returns (address token) {
        for (uint256 i = 0; i < 64; ++i) {
            bytes32 saltStart = bytes32(uint256(keccak256(abi.encodePacked(saltHint, i))));
            (bool ok, bytes memory ret) =
                address(this).call(abi.encodeCall(this.tryLaunchWithoutSeed, (saltStart)));
            if (ok) {
                return abi.decode(ret, (address));
            }
        }
        revert("Pons hermetic: vanity salt not found under gas budget");
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
