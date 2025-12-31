// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/constants/protocols/dexes/balancer/v3/BalancerV3_INITCODE.sol";
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";
// import { ScriptBase_Crane_ERC20 } from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {Script_BalancerV3} from "contracts/crane/script/protocols/Script_BalancerV3.sol";
import {TestBase_ICreate2Aware} from "contracts/crane/test/bases/TestBase_ICreate2Aware.sol";
import {IERC4626RateProvider} from "contracts/crane/interfaces/IERC4626RateProvider.sol";
import {IERC4626DFPkg} from 
// ERC4626DFPkg
"contracts/crane/token/ERC20/extensions/ERC4626DFPkg.sol";

contract IERC4626RateProvider_ICreate2Aware_Test is
    ScriptBase_Crane_ERC4626,
    Script_BalancerV3,
    TestBase_ICreate2Aware
{
    string underlyingName;
    string underlyingSymbol;
    uint8 underlyingDecimals;
    string underlyingVersion;
    uint256 underlyingTotalSupply;
    address underlyingRecipient;

    address underlying;

    string erc4626Name;
    string erc4626Symbol;
    uint8 decimalsOffset;
    IERC4626 erc4626Vault;

    IERC4626RateProvider erc4626RateProvider;
    bytes encodedArgs;

    function setUp()
        public
        override(
            // Script_BalancerV3,
            TestBase_ICreate2Aware
        )
    {
        owner(address(this));
        underlyingName = "Test ERC20";
        underlyingSymbol = "TERC20";
        underlyingDecimals = 18;
        underlyingVersion = "1";

        underlying = address(erc20Permit(underlyingName, underlyingSymbol, underlyingDecimals, underlyingVersion));

        erc4626Name = string.concat(underlyingName, " ERC4626 Vault");
        erc4626Symbol = "ERC4626";
        decimalsOffset = 0;

        IERC4626DFPkg.ERC4626DFPkgArgs memory pkgArgs = IERC4626DFPkg.ERC4626DFPkgArgs({
            underlying: underlying, decimalsOffset: decimalsOffset, name: erc4626Name, symbol: erc4626Symbol
        });

        erc4626Vault = erc4626(pkgArgs);

        encodedArgs = abi.encode(erc4626Vault);
    }

    function run() public override(ScriptBase_Crane_ERC4626, Script_BalancerV3, TestBase_ICreate2Aware) {
        // super.run(); // Comment out for performance - don't deploy unnecessary components
    }

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(address(balV3ERC4626RateProvider(erc4626Vault)));
    }

    function controlOrigin() public override returns (address) {
        return address(diamondFactory());
    }

    function controlInitCodeHash() public override returns (bytes32) {
        return diamondFactory().PROXY_INIT_HASH();
    }

    function controlSalt() public override returns (bytes32) {
        return balV3ERC4626RateProviderFacetDFPkg().calcSalt(encodedArgs);
    }
}
