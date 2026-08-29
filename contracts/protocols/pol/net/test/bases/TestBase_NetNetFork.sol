// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/external/openzeppelin-contracts/interfaces/IERC4626.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IMorpho} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {ROBINHOOD_MAIN} from "@crane/contracts/constants/networks/ROBINHOOD_MAIN.sol";

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
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";
import {NetNetAwareRepo} from "@crane/contracts/protocols/pol/net/aware/NetNetAwareRepo.sol";
import {NetNetSpotService} from "@crane/contracts/protocols/pol/net/services/NetNetSpotService.sol";

/**
 * @title TestBase_NetNetFork
 * @notice Binds live Official Channels addresses at `ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK`.
 */
abstract contract TestBase_NetNetFork is Test {
    IERC20 internal usdg;
    INET internal net;
    IsNET internal sNet;
    IStaking internal staking;
    ITreasury internal treasury;
    IBondDepository internal bondDepository;
    IInverseBond internal inverseBond;
    IPremiumSeller internal premiumSeller;
    ITaxCollector internal taxCollector;
    IPTEAM internal pTeam;
    IUniswapV2Pair internal pair;
    IUniswapV2Router02 internal router;
    TurboRouter internal turboRouter;
    IMorpho internal morpho;
    IERC4626 internal morphoVault;
    IPairOracle internal oracle;
    address internal wsNet;
    address internal zap;
    bytes32 internal loopbackMarketId;
    address internal pTeamHolder;

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("robinhood_mainnet"), ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK);
        usdg = IERC20(ROBINHOOD_MAIN.USDG);
        net = INET(ROBINHOOD_MAIN.NET);
        sNet = IsNET(ROBINHOOD_MAIN.SNET);
        staking = IStaking(ROBINHOOD_MAIN.NETNET_STAKING);
        treasury = ITreasury(ROBINHOOD_MAIN.NETNET_TREASURY);
        bondDepository = IBondDepository(ROBINHOOD_MAIN.NETNET_BOND_DEPOSITORY);
        inverseBond = IInverseBond(ROBINHOOD_MAIN.NETNET_INVERSE_BOND);
        premiumSeller = IPremiumSeller(ROBINHOOD_MAIN.NETNET_PREMIUM_SELLER);
        taxCollector = ITaxCollector(ROBINHOOD_MAIN.NETNET_TAX_COLLECTOR);
        pTeam = IPTEAM(ROBINHOOD_MAIN.NETNET_PTEAM);
        pair = IUniswapV2Pair(ROBINHOOD_MAIN.NETNET_NET_USDG_PAIR);
        router = IUniswapV2Router02(ROBINHOOD_MAIN.UNISWAP_V2_ROUTER02);
        turboRouter = TurboRouter(ROBINHOOD_MAIN.NETNET_LOOPBACK_TURBO_ROUTER);
        morpho = IMorpho(ROBINHOOD_MAIN.MORPHO);
        morphoVault = IERC4626(ROBINHOOD_MAIN.NETNET_STEAK_USDG);
        oracle = IPairOracle(ROBINHOOD_MAIN.NETNET_PAIR_ORACLE);
        wsNet = ROBINHOOD_MAIN.WSNET;
        zap = ROBINHOOD_MAIN.NETNET_ZAP;
        loopbackMarketId = ROBINHOOD_MAIN.NETNET_LOOPBACK_MARKET_ID;
        pTeamHolder = ROBINHOOD_MAIN.NETNET_TEAM_SAFE;

        NetNetAwareRepo._initialize(
            NetNetAwareRepo.NetNetAwareInit({
                usdg: usdg,
                net: net,
                sNet: sNet,
                staking: staking,
                treasury: treasury,
                bondDepository: bondDepository,
                inverseBond: inverseBond,
                premiumSeller: premiumSeller,
                taxCollector: taxCollector,
                pteam: pTeam,
                canonicalPair: pair,
                router: router,
                turboRouter: address(turboRouter),
                wsNet: wsNet,
                zap: zap,
                morpho: morpho,
                loopbackMarketId: loopbackMarketId,
                morphoVault: morphoVault,
                pTeamHolder: pTeamHolder
            })
        );
    }

    function _buyNet(uint256 usdgAmount, uint256 minNetOut) internal {
        NetNetSpotService._buyNetWithUsdg(
            NetNetSpotService.BuyParams({
                router: router,
                tokenIn: usdg,
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
                router: router,
                tokenIn: IERC20(address(net)),
                tokenOut: usdg,
                amountIn: netAmount,
                amountOutMin: minUsdgOut,
                to: address(this),
                deadline: block.timestamp
            })
        );
    }
}
