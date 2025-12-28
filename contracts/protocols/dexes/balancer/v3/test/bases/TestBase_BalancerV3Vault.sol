// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    HookFlags,

    // FEE_SCALING_FACTOR,
    Rounding,
    TokenConfig,
    TokenType
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC4626RateProviderFacetDFPkg, ERC4626RateProviderFacetDFPkg} from "contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol";
import {BaseTest} from "@balancer-labs/v3-solidity-utils/test/foundry/utils/BaseTest.sol";
import {BaseVaultTest} from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import {TestBase_BalancerV3} from "@crane/contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ERC4626RateProviderFactoryService} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol";

contract TestBase_BalancerV3Vault is TestBase_BalancerV3, BaseVaultTest {

    ICreate3Factory create3Factory;
    IDiamondPackageCallBackFactory diamondPackageFactory;

    IERC4626RateProviderFacetDFPkg erc4626RateProviderDFPkg;
    IRateProvider waDAIRateProvider;
    IRateProvider waWETHRateProvider;
    IRateProvider waUSDRateProvider;

    function setUp() public virtual
    override(
        BaseTest,
        BaseVaultTest
    ) {
        BaseVaultTest.setUp();
    }

    function onAfterDeployMainContracts() internal virtual override {
        (create3Factory, diamondPackageFactory) = InitDevService.initEnv(address(this));
        erc4626RateProviderDFPkg = ERC4626RateProviderFactoryService.initER4626RateProvicerDFPkg(create3Factory);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Initialization Options                           */
    /* -------------------------------------------------------------------------- */

    function deployERC4626RateProvider(IERC4626 asset) public virtual returns (IRateProvider) {
        return erc4626RateProviderDFPkg.deployRateProvider(asset);
    }

    function standardTokenConfig(IERC20 token) public virtual returns (TokenConfig memory) {
        return TokenConfig({
            token: token,
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });
    }

    function erc4626TokenConfig(IERC4626 token, IRateProvider rateProvider_, bool paysYieldFees) public virtual returns (TokenConfig memory) {
        return TokenConfig({
            token: IERC20(address(token)),
            tokenType: TokenType.WITH_RATE,
            rateProvider: rateProvider_,
            paysYieldFees: paysYieldFees
        });
    }

    function erc4626TokenConfig(IERC4626 token, bool paysYieldFees) public virtual returns (TokenConfig memory) {
        IRateProvider rateProvider_ = deployERC4626RateProvider(token);
        return erc4626TokenConfig(token, rateProvider_, paysYieldFees);
    }

    function erc4626TokenConfig(IERC4626 token) public virtual returns (TokenConfig memory) {
        IRateProvider rateProvider_ = deployERC4626RateProvider(token);
        return erc4626TokenConfig(token, rateProvider_, false);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Approval Helpers                            */
    /* ---------------------------------------------------------------------- */

    function _approveSpenderForAllUsers(address spender) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Entering function."));
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(spender);
            vm.stopPrank();
        }
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Exiting function."));
    }

    function approveForSender(address spender) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Entering function."));
        // console.log("BetterBalancerV3VaultTest.approveForSender():: Entering function.");
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, type(uint256).max);
            permit2.approve(address(tokens[i]), address(spender), type(uint160).max, type(uint48).max);
        }

        for (uint256 i = 0; i < oddDecimalTokens.length; ++i) {
            oddDecimalTokens[i].approve(spender, type(uint256).max);
            permit2.approve(address(oddDecimalTokens[i]), spender, type(uint160).max, type(uint48).max);
        }

        for (uint256 i = 0; i < erc4626Tokens.length; ++i) {
            erc4626Tokens[i].approve(spender, type(uint256).max);
            permit2.approve(address(erc4626Tokens[i]), address(spender), type(uint160).max, type(uint48).max);
        }
        // console.log("BetterBalancerV3VaultTest.approveForSender():: Exiting function.");
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Exiting function."));
    }

    function _approveForAllUsers(IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveForAllUsers():: Entering function."));
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(token);
            vm.stopPrank();
        }
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveForAllUsers():: Exiting function."));
    }

    function approveForSender(IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Entering function."));
        token.approve(address(permit2), type(uint256).max);
        permit2.approve(address(token), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(token), address(bufferRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(token), address(batchRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(token), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Exiting function."));
    }

    function _approveSpenderForAllUsers(address spender, IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Entering function."));
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(spender, token);
            vm.stopPrank();
        }
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Exiting function."));
    }

    function approveForSender(address spender, IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Entering function."));
        token.approve(spender, type(uint256).max);
        permit2.approve(address(token), address(spender), type(uint160).max, type(uint48).max);
        // permit2.approve(address(token), address(bufferRouter), type(uint160).max, type(uint48).max);
        // permit2.approve(address(token), address(batchRouter), type(uint160).max, type(uint48).max);
        // permit2.approve(address(token), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Exiting function."));
    }

    function mintPoolTokens(address[] memory poolsTokens, uint256[] memory tokenInitAmounts)
        public
        virtual
        returns (uint256[] memory updatedTokenInitAmounts)
    {
        // console.log(
        //     string.concat(
        //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name, ".mintPoolTokens():: Entering function."
        //     )
        // );
        updatedTokenInitAmounts = new uint256[](tokenInitAmounts.length);
        for (uint256 cursor = 0; cursor < poolsTokens.length; cursor++) {
            // console.log(
            //     string.concat(
            //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
            //         ".mintPoolTokens():: Minting ",
            //         IERC20(poolsTokens[cursor]).name(),
            //         " tokens."
            //     )
            // );
            if (address(poolsTokens[cursor]) == address(dai)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting DAI tokens."
                //     )
                // );
                dai.mint(lp, tokenInitAmounts[cursor]);
                // updatedTokenInitAmounts[cursor] = tokenInitAmounts[cursor];
                updatedTokenInitAmounts[cursor] = dai.balanceOf(lp);
            } else if (address(poolsTokens[cursor]) == address(usdc)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting USDC tokens."
                //     )
                // );
                usdc.mint(lp, tokenInitAmounts[cursor]);
                // updatedTokenInitAmounts[cursor] = tokenInitAmounts[cursor];
                updatedTokenInitAmounts[cursor] = usdc.balanceOf(lp);
            } else if (address(poolsTokens[cursor]) == address(weth)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting WETH tokens."
                //     )
                // );
                deal(lp, tokenInitAmounts[cursor]);
                // deal(lp, type(uint256).max);
                vm.startPrank(lp);
                weth.deposit{value: tokenInitAmounts[cursor]}();
                // weth.deposit{ value: tokenInitAmounts[cursor] }();
                // payable(address(weth)).transfer(tokenInitAmounts[cursor]);
                vm.stopPrank();
                // updatedTokenInitAmounts[cursor] = tokenInitAmounts[cursor];
                updatedTokenInitAmounts[cursor] = weth.balanceOf(lp);
            } else if (address(poolsTokens[cursor]) == address(waDAI)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting waDAI tokens."
                //     )
                // );
                dai.mint(lp, tokenInitAmounts[cursor]);
                vm.startPrank(lp);
                updatedTokenInitAmounts[cursor] = waDAI.deposit(tokenInitAmounts[cursor], lp);
                vm.stopPrank();
            } else if (address(poolsTokens[cursor]) == address(waUSDC)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting waUSDC tokens."
                //     )
                // );
                usdc.mint(lp, tokenInitAmounts[cursor]);
                vm.startPrank(lp);
                updatedTokenInitAmounts[cursor] = waUSDC.deposit(tokenInitAmounts[cursor], lp);
                vm.stopPrank();
            } else if (address(poolsTokens[cursor]) == address(waWETH)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting waWETH tokens."
                //     )
                // );
                deal(lp, tokenInitAmounts[cursor]);
                vm.startPrank(lp);
                weth.deposit{value: tokenInitAmounts[cursor]}();
                updatedTokenInitAmounts[cursor] = waWETH.deposit(tokenInitAmounts[cursor], lp);
                vm.stopPrank();
            }
        }
        // console.log(
        //     string.concat(
        //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name, ".mintPoolTokens():: Exiting function."
        //     )
        // );
    }

}