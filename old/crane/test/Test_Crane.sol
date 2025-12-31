// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {Test} from "forge-std/Test.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

// import {Permit2Helpers} from "@balancer-labs/v3-vault/test/foundry/utils/Permit2Helpers.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "@crane/src/constants/Constants.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {Script_Crane} from "contracts/crane/script/Script_Crane.sol";
// import {Behavior_Crane} from "contracts/crane/test/behaviors/Behavior_Crane.sol";
// import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
// import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
// import {IERC5115} from "contracts/crane/interfaces/IERC5115.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
// import {
//     BetterIERC20Permit as IERC20Permit
// } from "contracts/crane/interfaces/BetterIERC20Permit.sol";
import {Script_Crane_Stubs} from "contracts/crane/script/Script_Crane_Stubs.sol";
import {BetterTest} from "contracts/crane/test/BetterTest.sol";

contract Test_Crane is
    CommonBase,
    ScriptBase,
    TestBase,
    StdAssertions,
    StdChains,
    StdCheatsSafe,
    StdCheats,
    StdInvariant,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,
    Script_Crane,
    Script_Crane_Stubs,
    Test,
    BetterTest
{
    function setUp() public virtual {
        setDeployer(address(this));
        setOwner(address(this));
    }

    function run()
        public
        virtual
        override(
            ScriptBase_Crane_Factories,
            ScriptBase_Crane_ERC20,
            ScriptBase_Crane_ERC4626,
            Script_Crane,
            Script_Crane_Stubs
        )
    {
        // ScriptBase_Crane_Factories.run();
        // ScriptBase_Crane_ERC20.run();
        // ScriptBase_Crane_ERC4626.run();
        // Script_Crane.run();
        Script_Crane_Stubs.run();
    }

    VmSafe.Wallet internal _marketWallet = vm.createWallet("market");

    function marketWallet() public view virtual returns (VmSafe.Wallet memory) {
        return _marketWallet;
    }

    function market() public view virtual returns (address) {
        return marketWallet().addr;
    }

    VmSafe.Wallet internal _traderWallet = vm.createWallet("trader");

    function traderWallet() public view virtual returns (VmSafe.Wallet memory) {
        return _traderWallet;
    }

    function trader() public view virtual returns (address) {
        // return address(this);
        return traderWallet().addr;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
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
