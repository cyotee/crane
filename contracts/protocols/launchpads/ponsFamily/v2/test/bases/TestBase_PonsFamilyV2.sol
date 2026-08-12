// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";

import {IWETH9} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/external/IWETH9.sol";
import {WETH} from "@crane/contracts/protocols/dexes/uniswap/v4/external/solmate/tokens/WETH.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {PoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PoolManager.sol";
import {IPositionManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPositionManager.sol";
import {PositionManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PositionManager.sol";
import {PositionDescriptor} from "@crane/contracts/protocols/dexes/uniswap/v4/PositionDescriptor.sol";
import {IPositionDescriptor} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPositionDescriptor.sol";
import {Hooks} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/Hooks.sol";
import {HookMiner} from "@crane/contracts/protocols/dexes/uniswap/v4/utils/HookMiner.sol";
import {IAllowanceTransfer} from "@crane/contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol";
import {DeployPermit2} from "@crane/contracts/protocols/utils/permit2/test/utils/DeployPermit2.sol";

import {PonsV2FeeEscrow} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2FeeEscrow.sol";
import {PonsV2BuybackVault} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2BuybackVault.sol";
import {PonsV2LaunchLocker} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2LaunchLocker.sol";
import {PonsV2MemeHook} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/hooks/PonsV2MemeHook.sol";
import {PonsV2LaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2LaunchFactory.sol";
import {PonsV2LaunchDeployer} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2LaunchDeployer.sol";
import {PonsV2GraduationExecutor} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2GraduationExecutor.sol";
import {PonsV2LauncherToken} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2LauncherToken.sol";
import {PonsV2BondingCurve} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/PonsV2BondingCurve.sol";
import {IPonsV2LaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/v2/interfaces/ILaunchpadV2.sol";

/**
 * @title TestBase_PonsFamilyV2
 * @notice Hermetic full-stack setup for pons v2: Uni V4 + Permit2 + fee escrow +
 * meme hook (CREATE2-mined permissions) + vault + locker + factory + deployer +
 * graduation executor. No RPC.
 */
abstract contract TestBase_PonsFamilyV2 is Test {
    /* -------------------------------------------------------------------------- */
    /*                         Live-aligned hermetic defaults                     */
    /* -------------------------------------------------------------------------- */

    uint256 internal constant PONS_V2_LAUNCH_FEE = 0.0005 ether;
    uint256 internal constant PONS_V2_SUPPLY = 1_000_000_000 ether;
    /// @dev Phantom + threshold sized so a few ETH of buys can exercise the curve
    /// without exhausting gas on full sell-out in unit tests.
    uint256 internal constant PONS_V2_PHANTOM_QUOTE = 1 ether;
    uint256 internal constant PONS_V2_GRADUATION_THRESHOLD = 4.2 ether;
    uint256 internal constant PONS_V2_CURVE_FEE_BPS = 100; // 1%
    uint24 internal constant PONS_V2_POOL_FEE = 0; // hook takes fees
    int24 internal constant PONS_V2_TICK_SPACING = 60;

    uint160 internal constant MEME_HOOK_FLAGS = uint160(
        Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG
    );

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    IWETH9 internal weth;
    IPoolManager internal poolManager;
    IPositionManager internal positionManager;
    IAllowanceTransfer internal permit2;
    IPositionDescriptor internal positionDescriptor;

    PonsV2FeeEscrow internal ponsV2FeeEscrow;
    PonsV2MemeHook internal ponsV2MemeHook;
    PonsV2BuybackVault internal ponsV2BuybackVault;
    PonsV2LaunchLocker internal ponsV2Locker;
    PonsV2LaunchFactory internal ponsV2Factory;
    PonsV2LaunchDeployer internal ponsV2LaunchDeployer;
    PonsV2GraduationExecutor internal ponsV2GraduationExecutor;

    address internal ponsV2Owner;
    address internal ponsV2FeeSink;
    address internal ponsV2Launcher;

    uint256 internal ponsV2LaunchConfigId;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        if (address(ponsV2Factory) != address(0)) return;

        ponsV2Owner = makeAddr("ponsV2Owner");
        ponsV2FeeSink = makeAddr("ponsV2FeeSink");
        ponsV2Launcher = makeAddr("ponsV2Launcher");

        weth = IWETH9(address(new WETH()));
        vm.label(address(weth), "weth");

        // Canonical Permit2 via etched production bytecode.
        DeployPermit2 permit2Deployer = new DeployPermit2();
        permit2 = IAllowanceTransfer(permit2Deployer.deployPermit2());
        vm.label(address(permit2), "permit2");

        poolManager = IPoolManager(address(new PoolManager(ponsV2Owner)));
        vm.label(address(poolManager), "poolManager");

        positionDescriptor = new PositionDescriptor(poolManager, address(weth), bytes32("ETH"));
        positionManager = IPositionManager(
            address(
                new PositionManager(
                    poolManager,
                    permit2,
                    100_000, // unsubscribeGasLimit
                    positionDescriptor,
                    weth
                )
            )
        );
        vm.label(address(positionManager), "positionManager");

        ponsV2FeeEscrow = new PonsV2FeeEscrow();
        vm.label(address(ponsV2FeeEscrow), "ponsV2FeeEscrow");

        // Mine hook address with Uniswap V4 permission flags, then CREATE2-deploy.
        bytes memory hookArgs = abi.encode(poolManager, ponsV2FeeEscrow, ponsV2FeeSink, ponsV2Owner);
        (address predictedHook, bytes32 hookSalt) =
            HookMiner.find(address(this), MEME_HOOK_FLAGS, type(PonsV2MemeHook).creationCode, hookArgs);
        ponsV2MemeHook = new PonsV2MemeHook{salt: hookSalt}(
            poolManager, ponsV2FeeEscrow, ponsV2FeeSink, ponsV2Owner
        );
        require(address(ponsV2MemeHook) == predictedHook, "hook address mismatch");
        vm.label(address(ponsV2MemeHook), "ponsV2MemeHook");

        vm.startPrank(ponsV2Owner);
        ponsV2BuybackVault = new PonsV2BuybackVault(ponsV2Owner, ponsV2MemeHook, ponsV2FeeEscrow);
        ponsV2Locker = new PonsV2LaunchLocker(ponsV2Owner, address(positionManager));

        ponsV2Factory = new PonsV2LaunchFactory(
            ponsV2Owner,
            poolManager,
            positionManager,
            permit2,
            ponsV2Locker,
            ponsV2MemeHook,
            ponsV2FeeEscrow,
            ponsV2BuybackVault,
            PONS_V2_LAUNCH_FEE
        );

        ponsV2LaunchDeployer = new PonsV2LaunchDeployer(address(ponsV2Factory));
        ponsV2GraduationExecutor =
            new PonsV2GraduationExecutor(positionManager, permit2, ponsV2Locker, address(ponsV2Factory));

        // One-time wiring (production deploy order).
        ponsV2MemeHook.setFactory(address(ponsV2Factory));
        ponsV2MemeHook.setBuybackVault(ponsV2BuybackVault);
        ponsV2BuybackVault.setFactory(address(ponsV2Factory));
        ponsV2Locker.setFactory(address(ponsV2Factory));
        ponsV2Factory.setLaunchDeployer(ponsV2LaunchDeployer);
        ponsV2Factory.setGraduationExecutor(ponsV2GraduationExecutor);

        ponsV2LaunchConfigId = ponsV2Factory.addLaunchConfig(
            PonsV2LaunchFactory.LaunchConfig({
                supply: PONS_V2_SUPPLY,
                curveFeeBps: PONS_V2_CURVE_FEE_BPS,
                phantomQuote: PONS_V2_PHANTOM_QUOTE,
                graduationThreshold: PONS_V2_GRADUATION_THRESHOLD,
                poolFee: PONS_V2_POOL_FEE,
                tickSpacing: PONS_V2_TICK_SPACING,
                enabled: true
            })
        );
        // Disable snipe tax in hermetic defaults so small buys are predictable.
        ponsV2Factory.setSnipeTaxStartBps(0);
        ponsV2Factory.setLaunchEnabled(true);
        vm.stopPrank();

        vm.label(address(ponsV2Factory), "ponsV2Factory");
        vm.label(address(ponsV2BuybackVault), "ponsV2BuybackVault");
        vm.label(address(ponsV2Locker), "ponsV2Locker");
        vm.label(address(ponsV2LaunchDeployer), "ponsV2LaunchDeployer");
        vm.label(address(ponsV2GraduationExecutor), "ponsV2GraduationExecutor");

        vm.deal(ponsV2Launcher, 100 ether);
        vm.deal(address(this), 100 ether);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Helpers                                   */
    /* -------------------------------------------------------------------------- */

    function _defaultV2TokenParams(string memory name_, string memory symbol_)
        internal
        pure
        returns (PonsV2LaunchFactory.TokenParams memory)
    {
        return PonsV2LaunchFactory.TokenParams({
            name: name_,
            symbol: symbol_,
            logo: "ipfs://logo",
            description: "hermetic pons v2 launch",
            socials: PonsV2LauncherToken.Socials({
                twitter: "https://x.com/pons",
                telegram: "",
                discord: "",
                website: "https://pons.family",
                farcaster: ""
            }),
            creatorFeeRecipient: address(0),
            creatorTaxBps: 0,
            buybackEnabled: false,
            expectedEconomics: bytes32(0),
            salt: keccak256(abi.encodePacked(name_, symbol_))
        });
    }

    function _defaultV2TokenParams() internal pure returns (PonsV2LaunchFactory.TokenParams memory) {
        return _defaultV2TokenParams("Pons V2 Hermetic", "PHV2");
    }

    /// @dev Launch with native ETH quote as `ponsV2Launcher`.
    function _launchV2(PonsV2LaunchFactory.TokenParams memory params)
        internal
        returns (address token, address curve)
    {
        vm.prank(ponsV2Launcher);
        (token, curve) =
            ponsV2Factory.launchToken{value: PONS_V2_LAUNCH_FEE}(params, ponsV2LaunchConfigId, address(0));
    }

    function _launchedV2(address token) internal view returns (IPonsV2LaunchFactory.LaunchedToken memory) {
        return ponsV2Factory.getLaunchedToken(token);
    }
}
