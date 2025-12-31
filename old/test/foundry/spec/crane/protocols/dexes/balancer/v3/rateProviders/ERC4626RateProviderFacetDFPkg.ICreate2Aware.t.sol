// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/constants/protocols/dexes/balancer/v3/BalancerV3_INITCODE.sol";
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";
import {Script_BalancerV3} from "contracts/crane/script/protocols/Script_BalancerV3.sol";
import {TestBase_ICreate2Aware} from "contracts/crane/test/bases/TestBase_ICreate2Aware.sol";

contract ERC4626RateProviderFacetDFPkg_ICreate2Aware_Test is Script_BalancerV3, TestBase_ICreate2Aware {
    function setUp()
        public
        override(
            // Script_BalancerV3,
            TestBase_ICreate2Aware
        )
    {
        owner(address(this));
    }

    function run() public override(Script_BalancerV3, TestBase_ICreate2Aware) {
        // super.run(); // Comment out for performance - don't deploy unnecessary components
    }

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(address(balV3ERC4626RateProviderFacetDFPkg()));
    }

    function controlOrigin() public override returns (address) {
        return address(factory());
    }

    function controlInitCodeHash() public pure override returns (bytes32) {
        return ERC4626_RATE_PROVIDER_FACET_DFPKG_INITCODE_HASH;
    }

    function controlSalt() public pure override returns (bytes32) {
        return ERC4626_RATE_PROVIDER_FACET_DFPKG_SALT;
    }
}
