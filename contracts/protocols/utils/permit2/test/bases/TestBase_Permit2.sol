// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
// import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
// import {IVaultFeeOracleQuery} from "contracts/interfaces/IVaultFeeOracleQuery.sol";
// import {TestBase_UniswapV2} from "@crane/contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol";
// import {IndexedexTest} from "contracts/test/IndexedexTest.sol";
import {BetterPermit2} from "@crane/contracts/protocols/utils/permit2/BetterPermit2.sol";
import {BetterTest} from "@crane/contracts/test/BetterTest.sol";

contract TestBase_Permit2 is BetterTest {
    IPermit2 permit2;

    function setUp() public virtual override(BetterTest) {
        BetterTest.setUp();
        if(address(permit2) == address(0)) {
            permit2 = IPermit2(address(new BetterPermit2()));
        }
    }

}