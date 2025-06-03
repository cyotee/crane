// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";
import "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {Permit2Helpers} from "@balancer-labs/v3-vault/test/foundry/utils/Permit2Helpers.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "../constants/Constants.sol";
import {FoundryVM} from "../utils/vm/foundry/FoundryVM.sol";
import {BetterFuzzing} from "./fuzzing/BetterFuzzing.sol";
import {Fixture} from "../fixtures/Fixture.sol";
import {CraneFixture} from "../fixtures/CraneFixture.sol";
import {CraneScript} from "../script/CraneScript.sol";
import {CraneBehaviors} from "./behaviors/CraneBehaviors.sol";
import {ConstProdUtils} from "../utils/math/ConstProdUtils.sol";
import {BetterIERC20 as IERC20} from "../interfaces/BetterIERC20.sol";
import {IERC5115} from "../interfaces/IERC5115.sol";
import {ICamelotPair} from "../interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {
    BetterIERC20Permit as IERC20Permit
} from "../interfaces/BetterIERC20Permit.sol";
// import {
//     CamelotV2Fixture
// } from "../protocols/dexes/camelot/v2/fixtures/CamelotV2Fixture.sol";

contract CraneTest
is
// FoundryVM,
// Fixture,
// CamelotV2Fixture,
// CraneFixture,
// Script,
CraneScript,
// TODO Switch to having test bases for each behavior. Goal is to minimize the inherited test contract.
CraneBehaviors,
BetterFuzzing,
Test
{
    function initialize() public virtual
    override(
        // Fixture,
        // CamelotV2Fixture,
        // CraneFixture,
        CraneScript
    ) {
        CraneScript.initialize();
    }

    function setUp() public virtual
    override(
        CraneScript
        // CraneFixture,
        // CamelotV2Fixture,
        // Fixture
    ) {
        setDeployer(address(this));
        setOwner(address(this));
        CraneTest.initialize();
    }

    // VmSafe.Wallet internal _ownerWallet = vm.createWallet("owner");

    // function ownerWallet()
    // public view virtual returns(VmSafe.Wallet memory) {
    //     return _ownerWallet;
    // }

    // function owner()
    // public view virtual override returns(address) {
    //     return address(this);
    //     // return ownerWallet().addr;
    // }

    VmSafe.Wallet internal _marketWallet = vm.createWallet("market");

    function marketWallet()
    public view virtual returns(VmSafe.Wallet memory) {
        return _marketWallet;
    }

    function market()
    public view virtual returns(address) {
        return marketWallet().addr;
    }

    VmSafe.Wallet internal _traderWallet = vm.createWallet("trader");

    function traderWallet()
    public view virtual returns(VmSafe.Wallet memory) {
        return _traderWallet;
    }

    function trader()
    public view virtual returns(address) {
        // return address(this);
        return traderWallet().addr;
    }

    // TODO Move to CraneAsserts
    // TODO Inherit CraneAsserts into CraneTest
    // Approximation helper for comparing values with small precision differences
    function assertApproxEqualRelXY(uint256 x, uint256 y, uint256 precision) internal pure {
        if (precision == 0) {
            precision = 1;
        }
        
        uint256 maxValue = x > y ? x : y;
        uint256 minValue = x > y ? y : x;
        
        if (minValue == 0) {
            assertTrue(maxValue < precision, "Values not approximately equal");
            return;
        }
        
        uint256 diff = maxValue - minValue;
        assertTrue(diff * 1e18 / minValue < precision, "Values not approximately equal");
    }
    
    // function boundToConstProdPool(
    //     uint256 value,
    //     IERC20 tokenIn,
    //     address pool,
    //     uint256 tokenInRes,
    //     uint256 opposingTokenRes,
    //     uint256 feePercent,
    //     uint256 feeDenominator
    // ) public view returns (uint256 boundedValue) {
    // return bound(
    //         value,
    //         // HALF_WAD,
    //         ConstProdUtils._saleQuoteMin(
    //             tokenInRes,
    //             opposingTokenRes,
    //             feePercent,
    //             feeDenominator
    //         )
    //         + HALF_WAD,
    //         type(uint112).max
    //         // - (HALF_WAD / 2)
    //         - ONE_WAD
    //         // - 2
    //         - tokenIn.balanceOf(pool)
    //     );
    // }

    // function boundToCamV2Pool(
    //     uint256 value,
    //     IERC20 tokenIn,
    //     address pool
    // ) public view returns(uint256 boundedValue) {
    //     (uint256 token0Res, uint256 token1Res, uint256 fee0, uint256 fee1) = ICamelotPair(pool).getReserves();
    //     address token0 = ICamelotPair(pool).token0();
    //     return boundToConstProdPool(
    //         value,
    //         tokenIn,
    //         pool,
    //         address(tokenIn) == token0 ? token0Res : token1Res,
    //         address(tokenIn) == token0 ? token1Res : token0Res,
    //         address(tokenIn) == token0 ? fee1 : fee0,
    //         FEE_DENOMINATOR
    //     );
    // }

    // function getPermitSignature(
    //     address owner_,
    //     address spender,
    //     uint256 value,
    //     uint256 deadline,
    //     uint256 nonce,
    //     address token,
    //     uint256 privateKey
    // ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
    //     bytes32 DOMAIN_SEPARATOR = IERC20Permit(token).DOMAIN_SEPARATOR();
    //     bytes32 PERMIT_TYPEHASH = keccak256(
    //         "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    //     );
        
    //     bytes32 structHash = keccak256(
    //         abi.encode(
    //             PERMIT_TYPEHASH,
    //             owner_,
    //             spender,
    //             value,
    //             nonce,
    //             deadline
    //         )
    //     );

    //     bytes32 digest = keccak256(
    //         abi.encodePacked(
    //             "\x19\x01",
    //             DOMAIN_SEPARATOR,
    //             structHash
    //         )
    //     );

    //     (v, r, s) = vm.sign(privateKey, digest);
    // }

    // function estimateMinDeposit(address vault, address tokenIn) public view returns (uint256) {
    //     uint256 totalSupply = IERC20(vault).totalSupply();
    //     if (totalSupply == 0) {
    //         return 1e18; // For initial deposit, use a reasonable minimum
    //     }

    //     // Estimate based on share price: how much tokenIn is needed to get at least 1 share
    //     uint256 sharePrice = IERC5115(vault).previewDeposit(tokenIn, 1e18);
    //     if (sharePrice == 0) {
    //         return 1e18; // Default to 1 APE if preview fails or share price is zero
    //     }

    //     // Calculate the minimum deposit to mint at least 1 share
    //     // This is a simplified approach; adjust based on your vault’s specific logic
    //     return (1e18 * 1e18) / sharePrice + 1; // Ensure at least 1 share, accounting for rounding
    // }

    // function calculateMinDeposit(address pool, IERC20 token) public view returns (uint256) {
    //     (uint256 reserve0, uint256 reserve1,,) = ICamelotPair(pool).getReserves();
    //     address token0 = ICamelotPair(pool).token0();
    //     uint256 reserve = token0 == address(token) ? reserve0 : reserve1;

    //     // Minimum deposit is 0.0001% of the reserve, with a floor of 1e18
    //     uint256 minDeposit = reserve / 1_000_000;
    //     return minDeposit > 1e18 ? minDeposit : 1e18;
    // }

}