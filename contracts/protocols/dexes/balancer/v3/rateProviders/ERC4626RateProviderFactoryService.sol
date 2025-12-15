// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3Factory} from "contracts/interfaces/ICreate3Factory.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {ERC4626RateProviderFacet} from "contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacet.sol";
import {IERC4626RateProviderFacetDFPkg, ERC4626RateProviderFacetDFPkg} from "contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol";

library ERC4626RateProviderFactoryService {
    using BetterEfficientHashLib for bytes;
    
    function initER4626RateProvicerDFPkg(
        ICreate3Factory create3Factory
    ) internal returns (IERC4626RateProviderFacetDFPkg erc4626RateProviderDFPkg) {
        IFacet erc4626RateProviderFacet = create3Factory.deployFacet(
            type(ERC4626RateProviderFacet).creationCode,
            abi.encode(type(ERC4626RateProviderFacet).name)._hash()
        );
        erc4626RateProviderDFPkg = IERC4626RateProviderFacetDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(ERC4626RateProviderFacetDFPkg).creationCode,
                    abi.encode(
                        IERC4626RateProviderFacetDFPkg.PkgInit({
                            erc4626RateProviderFacet: erc4626RateProviderFacet,
                            diamondPackageFactory: create3Factory.diamondPackageFactory()
                        })
                    ),
                    abi.encode(type(ERC4626RateProviderFacetDFPkg).name)._hash()
                )
            )
        );
    }

}