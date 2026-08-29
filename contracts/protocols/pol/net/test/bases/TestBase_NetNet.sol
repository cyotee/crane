// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IMorpho, MarketParams, Id} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {Morpho} from "@crane/contracts/external/morpho/blue/Morpho.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";
import {AdaptiveCurveIrm} from "@crane/contracts/external/morpho/blue-irm/AdaptiveCurveIrm.sol";
import {VaultV2} from "@crane/contracts/external/morpho/vault-v2/VaultV2.sol";
import {TestBase_UniswapV2} from
    "@crane/contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol";

import {NET} from "@crane/contracts/protocols/pol/net/src/NET.sol";
import {StakedNET} from "@crane/contracts/protocols/pol/net/src/StakedNET.sol";
import {Staking} from "@crane/contracts/protocols/pol/net/src/Staking.sol";
import {Treasury} from "@crane/contracts/protocols/pol/net/src/Treasury.sol";
import {Distributor} from "@crane/contracts/protocols/pol/net/src/Distributor.sol";
import {BondDepository} from "@crane/contracts/protocols/pol/net/src/BondDepository.sol";
import {InverseBond} from "@crane/contracts/protocols/pol/net/src/InverseBond.sol";
import {PremiumSeller} from "@crane/contracts/protocols/pol/net/src/PremiumSeller.sol";
import {PairOracle} from "@crane/contracts/protocols/pol/net/src/PairOracle.sol";
import {TaxCollector} from "@crane/contracts/protocols/pol/net/src/TaxCollector.sol";
import {PTeam} from "@crane/contracts/protocols/pol/net/src/PTeam.sol";
import {GenesisBond} from "@crane/contracts/protocols/pol/net/src/GenesisBond.sol";
import {ShareCertificate} from "@crane/contracts/protocols/pol/net/src/ShareCertificate.sol";
import {LoopbackOracle} from "@crane/contracts/protocols/pol/net/src/lending/LoopbackOracle.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";
import {WrappedStakedNET} from "@crane/contracts/protocols/pol/net/src/perp/WrappedStakedNET.sol";
import {Zap} from "@crane/contracts/protocols/pol/net/src/perp/Zap.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {LendingConstants} from "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {IInverseBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IInverseBond.sol";
import {IPremiumSeller} from "@crane/contracts/protocols/pol/net/src/interfaces/IPremiumSeller.sol";
import {ITaxCollector} from "@crane/contracts/protocols/pol/net/src/interfaces/ITaxCollector.sol";
import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";

import {NetNetAwareRepo} from "@crane/contracts/protocols/pol/net/aware/NetNetAwareRepo.sol";
import {NetNetSpotService} from "@crane/contracts/protocols/pol/net/services/NetNetSpotService.sol";
import {NetNetUsdg} from "@crane/contracts/protocols/pol/net/test/bases/NetNetUsdg.sol";

/**
 * @title TestBase_NetNet
 * @notice Hermetic NetNet boot: Crane Uni V2, real Morpho Blue, real Vault V2, real `wire()` + `GenesisBond.finalize()`.
 * @dev Does not inherit `TestBase_MorphoBlue`. No `vm.mockCall` on the SUT list.
 */
abstract contract TestBase_NetNet is TestBase_UniswapV2 {
    using MarketParamsLib for MarketParams;

    uint256 internal constant FOUNDER_COUNT = 8;
    uint256 internal constant GENESIS_WALLET_USDG = 2_000e6;

    NetNetUsdg internal usdg;
    IMorpho internal morpho;
    AdaptiveCurveIrm internal irm;
    VaultV2 internal vault;

    address internal pTeamHolder;
    address internal guardian;
    address internal teamWallet;
    address internal uniV3Factory;

    NET internal net;
    StakedNET internal sNet;
    IUniswapV2Pair internal pair;
    Treasury internal treasury;
    PairOracle internal oracle;
    Staking internal staking;
    GenesisBond internal genesisBond;
    ShareCertificate internal shareCertificate;
    Distributor internal distributor;
    BondDepository internal bondDepository;
    InverseBond internal inverseBond;
    PremiumSeller internal premiumSeller;
    TaxCollector internal taxCollector;
    PTeam internal pTeam;
    WrappedStakedNET internal wsNet;
    Zap internal zap;
    LoopbackOracle internal loopbackOracle;
    TurboRouter internal turboRouter;

    address[FOUNDER_COUNT] internal founders;
    MarketParams internal loopbackMarket;
    bytes32 internal loopbackMarketId;

    function setUp() public virtual override {
        TestBase_UniswapV2.setUp();
        _deployInfra();
        _deployDomain();
        _wireDomain();
        _runGenesis();
        _seedOracleTwap();
        _enableLoopbackMarket();
        _initAware();
    }

    function _deployInfra() internal {
        usdg = new NetNetUsdg();
        morpho = IMorpho(address(new Morpho(address(this))));
        irm = new AdaptiveCurveIrm(address(morpho));
        vault = new VaultV2(address(this), address(usdg));
        pTeamHolder = address(this);
        guardian = address(this);
        teamWallet = address(this);
        uniV3Factory = makeAddr("netnetUniV3Factory");
        vm.label(address(usdg), "USDG");
        vm.label(address(morpho), "Morpho");
        vm.label(address(irm), "AdaptiveCurveIrm");
        vm.label(address(vault), "VaultV2");
    }

    function _deployDomain() internal {
        net = new NET(guardian);
        sNet = new StakedNET();
        pair = IUniswapV2Pair(uniswapV2Factory.createPair(address(net), address(usdg)));
        treasury = new Treasury(address(net), address(usdg), address(vault), address(pair));
        oracle = new PairOracle(address(pair), address(net), address(usdg));
        staking = new Staking(address(net), address(sNet), Constants.STAKING_WARMUP_EPOCHS);
        genesisBond = new GenesisBond(
            address(net), address(usdg), address(treasury), address(staking), address(pair), address(oracle)
        );
        shareCertificate = new ShareCertificate(address(genesisBond));
        distributor = new Distributor(
            address(treasury), address(net), address(sNet), address(staking), address(oracle)
        );
        bondDepository = new BondDepository(
            address(net), address(usdg), address(pair), address(oracle), address(treasury)
        );
        inverseBond = new InverseBond(
            address(net), address(usdg), address(treasury), address(oracle), address(genesisBond)
        );
        IUniswapV2Router02 router02 = IUniswapV2Router02(address(uniswapV2Router));
        premiumSeller = new PremiumSeller(
            address(net),
            address(usdg),
            address(router02),
            address(pair),
            address(treasury),
            address(oracle),
            address(genesisBond)
        );
        taxCollector = new TaxCollector(
            address(net),
            address(usdg),
            address(router02),
            address(pair),
            address(oracle),
            address(treasury),
            teamWallet
        );
        pTeam = new PTeam(address(net), address(usdg), address(treasury), pTeamHolder);
        wsNet = new WrappedStakedNET(address(sNet));
        zap = new Zap(address(net), address(sNet), address(staking), address(wsNet));
        loopbackOracle = new LoopbackOracle(address(oracle), address(treasury), address(sNet), address(net));
        turboRouter = new TurboRouter(
            address(morpho),
            address(usdg),
            address(net),
            address(sNet),
            address(staking),
            address(wsNet),
            address(zap),
            address(router02),
            address(loopbackOracle),
            address(irm)
        );
        vm.label(address(net), "NET");
        vm.label(address(sNet), "sNET");
        vm.label(address(pair), "NET/USDG");
        vm.label(address(treasury), "Treasury");
        vm.label(address(staking), "Staking");
        vm.label(address(genesisBond), "GenesisBond");
        vm.label(address(turboRouter), "TurboRouter");
    }

    function _wireDomain() internal {
        address[] memory exempt = new address[](3);
        exempt[0] = address(taxCollector);
        exempt[1] = address(premiumSeller);
        exempt[2] = address(turboRouter);
        address[] memory taxed = new address[](1);
        taxed[0] = address(pair);
        net.wire(
            address(treasury),
            address(taxCollector),
            address(genesisBond),
            address(uniswapV2Factory),
            uniV3Factory,
            exempt,
            taxed
        );
        sNet.wire(address(staking));
        staking.wire(address(distributor), address(oracle), address(genesisBond));
        address[] memory minters = new address[](5);
        minters[0] = address(distributor);
        minters[1] = address(genesisBond);
        minters[2] = address(bondDepository);
        minters[3] = address(premiumSeller);
        minters[4] = address(pTeam);
        address[] memory spenders = new address[](1);
        spenders[0] = address(inverseBond);
        treasury.wire(minters, spenders);
        bondDepository.wire(address(genesisBond));
        taxCollector.wire(address(pTeam));
        genesisBond.wire(address(bondDepository), address(shareCertificate));
        address[] memory excluded = new address[](5);
        excluded[0] = address(treasury);
        excluded[1] = address(inverseBond);
        excluded[2] = address(taxCollector);
        excluded[3] = address(genesisBond);
        excluded[4] = address(bondDepository);
        pTeam.wire(address(genesisBond), excluded);
    }

    function _runGenesis() internal {
        for (uint256 i; i < FOUNDER_COUNT; ++i) {
            founders[i] = makeAddr(string.concat("netnetFounder", vm.toString(i)));
            usdg.mint(founders[i], GENESIS_WALLET_USDG);
            vm.startPrank(founders[i]);
            usdg.approve(address(genesisBond), GENESIS_WALLET_USDG);
            genesisBond.purchase(GENESIS_WALLET_USDG);
            vm.stopPrank();
        }
        vm.warp(block.timestamp + Constants.GENESIS_DEADLINE + 1);
        genesisBond.finalize();
    }

    function _seedOracleTwap() internal {
        vm.warp(block.timestamp + Constants.CHECKPOINT_MIN_INTERVAL);
        oracle.checkpoint();
        vm.warp(block.timestamp + Constants.TWAP_MIN_WINDOW);
        oracle.checkpoint();
    }

    function _enableLoopbackMarket() internal {
        morpho.enableIrm(address(irm));
        morpho.enableLltv(LendingConstants.LLTV);
        loopbackMarket = MarketParams({
            loanToken: address(usdg),
            collateralToken: address(wsNet),
            oracle: address(loopbackOracle),
            irm: address(irm),
            lltv: LendingConstants.LLTV
        });
        morpho.createMarket(loopbackMarket);
        loopbackMarketId = Id.unwrap(loopbackMarket.id());
        uint256 credit = 1_000_000e6;
        usdg.mint(address(this), credit);
        usdg.approve(address(morpho), credit);
        morpho.supply(loopbackMarket, credit, 0, address(this), "");
    }

    function _initAware() internal {
        NetNetAwareRepo._initialize(
            NetNetAwareRepo.NetNetAwareInit({
                usdg: IERC20(address(usdg)),
                net: INET(address(net)),
                sNet: IsNET(address(sNet)),
                staking: IStaking(address(staking)),
                treasury: ITreasury(address(treasury)),
                bondDepository: IBondDepository(address(bondDepository)),
                inverseBond: IInverseBond(address(inverseBond)),
                premiumSeller: IPremiumSeller(address(premiumSeller)),
                taxCollector: ITaxCollector(address(taxCollector)),
                pteam: IPTEAM(address(pTeam)),
                canonicalPair: pair,
                router: IUniswapV2Router02(address(uniswapV2Router)),
                turboRouter: address(turboRouter),
                wsNet: address(wsNet),
                zap: address(zap),
                morpho: morpho,
                loopbackMarketId: loopbackMarketId,
                morphoVault: IERC4626(address(vault)),
                pTeamHolder: pTeamHolder
            })
        );
    }

    function _router02() internal view returns (IUniswapV2Router02) {
        return IUniswapV2Router02(address(uniswapV2Router));
    }

    function _buyNet(uint256 usdgAmount, uint256 minNetOut) internal {
        NetNetSpotService._buyNetWithUsdg(
            NetNetSpotService.BuyParams({
                router: _router02(),
                tokenIn: IERC20(address(usdg)),
                tokenOut: IERC20(address(net)),
                amountIn: usdgAmount,
                amountOutMin: minNetOut,
                to: address(this),
                deadline: block.timestamp
            })
        );
    }

    function _sellNet(uint256 netAmount, uint256 minUsdgOut) internal {
        NetNetSpotService._sellNetForUsdg(
            NetNetSpotService.SellParams({
                router: _router02(),
                tokenIn: IERC20(address(net)),
                tokenOut: IERC20(address(usdg)),
                amountIn: netAmount,
                amountOutMin: minUsdgOut,
                to: address(this),
                deadline: block.timestamp
            })
        );
    }

    function _crashTwapBelowBacking() internal {
        vm.warp(block.timestamp + Constants.VEST_DURATION);
        uint256 exercisable = pTeam.exercisableNow();
        if (exercisable > 0) {
            uint256 paidWad =
                FixedPointMath.mulDiv(exercisable, Constants.PTEAM_STRIKE_WAD, Constants.NET_UNIT);
            uint256 paidRaw = FixedPointMath.mulDivUp(paidWad, 1, 1e12);
            usdg.mint(address(this), paidRaw);
            usdg.approve(address(pTeam), paidRaw);
            pTeam.exercise(exercisable);
        }
        uint256 bal = net.balanceOf(address(this));
        if (bal > 0) {
            _sellNet(bal, 0);
        }
        // Drop pre-dump TWAP observations out of the validity band.
        vm.warp(block.timestamp + Constants.TWAP_MAX_WINDOW + Constants.CHECKPOINT_MIN_INTERVAL);
        oracle.checkpoint();
        vm.warp(block.timestamp + Constants.TWAP_MIN_WINDOW);
        oracle.checkpoint();
        uint256 floor = treasury.backingPerToken() * (Constants.BPS - Constants.INVERSE_SPREAD_BPS)
            / Constants.BPS;
        for (uint256 i; i < 8 && oracle.twapNetUsdg() >= floor; ++i) {
            usdg.mint(address(this), 1_000e6);
            _buyNet(1_000e6, 0);
            uint256 again = net.balanceOf(address(this));
            if (again > 0) _sellNet(again, 0);
            vm.warp(block.timestamp + Constants.TWAP_MAX_WINDOW + Constants.CHECKPOINT_MIN_INTERVAL);
            oracle.checkpoint();
            vm.warp(block.timestamp + Constants.TWAP_MIN_WINDOW);
            oracle.checkpoint();
        }
    }

    function _liftTwapAbovePremium() internal {
        uint256 target = treasury.backingPerToken() * Constants.PREMIUM_THRESHOLD_WAD / Constants.WAD;
        for (uint256 i; i < 16; ++i) {
            usdg.mint(address(this), 50_000e6);
            _buyNet(50_000e6, 0);
            vm.warp(block.timestamp + Constants.CHECKPOINT_MIN_INTERVAL);
            oracle.checkpoint();
            vm.warp(block.timestamp + Constants.TWAP_MIN_WINDOW);
            oracle.checkpoint();
            if (oracle.twapNetUsdg() > target) return;
        }
    }
}
