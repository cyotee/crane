// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

pragma experimental ABIEncoderV2;

// 💬 ABOUT
// Forge Std's default Test.

// 🧩 MODULES
import {console} from "./console.sol";
import {console2} from "./console2.sol";
import {safeconsole} from "./safeconsole.sol";
import {StdAssertions} from "./StdAssertions.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {stdError} from "./StdError.sol";
import {StdInvariant} from "./StdInvariant.sol";
import {stdJson} from "./StdJson.sol";
import {stdMath} from "./StdMath.sol";
import {StdStorage, stdStorage} from "forge-std/StdStorage.sol";
import {StdStyle} from "./StdStyle.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Vm} from "./Vm.sol";

// 📦 BOILERPLATE
import {TestBase} from "./Base.sol";
import {DSTest} from "@crane/contracts/external/ds-test/test.sol";

// ⭐️ TEST
abstract contract Test is TestBase, DSTest, StdAssertions, StdChains, StdCheats, StdInvariant, StdUtils {
// Note: IS_TEST() must return true.
// Note: Must have failure system, https://github.com/dapphub/ds-test/blob/cd98eff28324bfac652e63a239a60632a761790b/src/test.sol#L39-L76.
}
