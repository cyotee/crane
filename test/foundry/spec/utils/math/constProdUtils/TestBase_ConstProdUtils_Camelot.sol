// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";
import {TestBase_CamelotV2} from "contracts/protocols/dexes/camelot/v2/TestBase_CamelotV2.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract TestBase_ConstProdUtils_Camelot is TestBase_CamelotV2 {
    // Test tokens for Camelot V2 - Balanced Pool
    ERC20PermitMintableStub camelotBalancedTokenA;
    ERC20PermitMintableStub camelotBalancedTokenB;

    // Test tokens for Camelot V2 - Unbalanced Pool
    ERC20PermitMintableStub camelotUnbalancedTokenA;
    ERC20PermitMintableStub camelotUnbalancedTokenB;

    // Test tokens for Camelot V2 - Extreme Unbalanced Pool
    ERC20PermitMintableStub camelotExtremeTokenA;
    ERC20PermitMintableStub camelotExtremeTokenB;

    // Camelot pairs for different configurations
    ICamelotPair camelotBalancedPair;
    ICamelotPair camelotUnbalancedPair;
    ICamelotPair camelotExtremeUnbalancedPair;

    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 1000e18;
    address constant REFERRER = address(0); // For Camelot

    // Unbalanced pool ratios
    uint256 constant UNBALANCED_RATIO_A = 10000e18; // 10,000 tokens
    uint256 constant UNBALANCED_RATIO_B = 1000e18; // 1,000 tokens (10:1 ratio)
    uint256 constant UNBALANCED_RATIO_C = 100e18; // 100 tokens (100:1 ratio)

    function setUp() public virtual override {
        TestBase_CamelotV2.setUp();
        _createCamelotTokens();
        _createCamelotPairs();
    }

    function _createCamelotTokens() internal {
        camelotBalancedTokenA = new ERC20PermitMintableStub("CamelotBalancedTokenA", "CAMBALA", 18, address(this), 0);
        vm.label(address(camelotBalancedTokenA), "CamelotBalancedTokenA");

        camelotBalancedTokenB = new ERC20PermitMintableStub("CamelotBalancedTokenB", "CAMBALB", 18, address(this), 0);
        vm.label(address(camelotBalancedTokenB), "CamelotBalancedTokenB");

        camelotUnbalancedTokenA = new ERC20PermitMintableStub("CamelotUnbalancedTokenA", "CAMUNA", 18, address(this), 0);
        vm.label(address(camelotUnbalancedTokenA), "CamelotUnbalancedTokenA");

        camelotUnbalancedTokenB = new ERC20PermitMintableStub("CamelotUnbalancedTokenB", "CAMUNB", 18, address(this), 0);
        vm.label(address(camelotUnbalancedTokenB), "CamelotUnbalancedTokenB");

        camelotExtremeTokenA = new ERC20PermitMintableStub("CamelotExtremeTokenA", "CAMEXA", 18, address(this), 0);
        vm.label(address(camelotExtremeTokenA), "CamelotExtremeTokenA");

        camelotExtremeTokenB = new ERC20PermitMintableStub("CamelotExtremeTokenB", "CAMEXB", 18, address(this), 0);
        vm.label(address(camelotExtremeTokenB), "CamelotExtremeTokenB");
    }

    function _createCamelotPairs() internal {
        camelotBalancedPair = ICamelotPair(camelotV2Factory.createPair(address(camelotBalancedTokenA), address(camelotBalancedTokenB)));
        vm.label(address(camelotBalancedPair), string.concat("CamelotBalancedPair - ", camelotBalancedTokenA.symbol(), " / ", camelotBalancedTokenB.symbol()));

        camelotUnbalancedPair = ICamelotPair(camelotV2Factory.createPair(address(camelotUnbalancedTokenA), address(camelotUnbalancedTokenB)));
        vm.label(address(camelotUnbalancedPair), string.concat("CamelotUnbalancedPair - ", camelotUnbalancedTokenA.symbol(), " / ", camelotUnbalancedTokenB.symbol()));

        camelotExtremeUnbalancedPair = ICamelotPair(camelotV2Factory.createPair(address(camelotExtremeTokenA), address(camelotExtremeTokenB)));
        vm.label(address(camelotExtremeUnbalancedPair), string.concat("CamelotExtremeUnbalancedPair - ", camelotExtremeTokenA.symbol(), " / ", camelotExtremeTokenB.symbol()));
    }

    function _initializeCamelotBalancedPools() internal {
        camelotBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        camelotBalancedTokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        camelotBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        camelotBalancedTokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(camelotV2Router, camelotBalancedTokenA, camelotBalancedTokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);
    }

    function _initializeCamelotUnbalancedPools() internal {
        camelotUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        camelotUnbalancedTokenA.approve(address(camelotV2Router), UNBALANCED_RATIO_A);
        camelotUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        camelotUnbalancedTokenB.approve(address(camelotV2Router), UNBALANCED_RATIO_B);

        CamelotV2Service._deposit(camelotV2Router, camelotUnbalancedTokenA, camelotUnbalancedTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_B);
    }

    function _initializeCamelotExtremeUnbalancedPools() internal {
        camelotExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        camelotExtremeTokenA.approve(address(camelotV2Router), UNBALANCED_RATIO_A);
        camelotExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        camelotExtremeTokenB.approve(address(camelotV2Router), UNBALANCED_RATIO_C);

        CamelotV2Service._deposit(camelotV2Router, camelotExtremeTokenA, camelotExtremeTokenB, UNBALANCED_RATIO_A, UNBALANCED_RATIO_C);
    }
}
