// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/common/IRateProvider.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import "@crane/contracts/GeneralErrors.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IERC4626RateProvider} from "@crane/contracts/interfaces/IERC4626RateProvider.sol";
import {
    ERC4626RateProviderRepo
} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {
    ERC4626RateProviderTarget
} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol";

// tag::ERC4626RateProviderFacet[]
/**
 * @title ERC4626RateProviderFacet - Reusable Diamond facet providing ERC4626-backed rate provider for Balancer V3 (implements IRateProvider + IERC4626RateProvider).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Extends ERC4626RateProviderTarget for business logic (delegates to ERC4626RateProviderRepo). Implements IFacet to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract ERC4626RateProviderFacet is ERC4626RateProviderTarget, IFacet {
    // using EfficientHashLib for bytes;

    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Returns the canonical name of this facet for Diamond registration and loupe queries.
     * @return name The name of this facet (type(ERC4626RateProviderFacet).name).
     * @custom:signature facetName()
     * @custom:selector 0x5b6f4d01
     */
    function facetName() public pure returns (string memory name) {
        return type(ERC4626RateProviderFacet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Returns the ERC-165 interface IDs supported by this facet (IRateProvider and IERC4626RateProvider).
     * @return interfaces Array of supported interface IDs.
     * @custom:signature facetInterfaces()
     * @custom:selector 0x2ea80826
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IRateProvider).interfaceId;
        interfaces[1] = type(IERC4626RateProvider).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Returns the function selectors implemented by this facet (getRate from IRateProvider; erc4626Vault from IERC4626RateProvider).
     * @return funcs Array of function selectors exposed via this facet.
     * @custom:signature facetFuncs()
     * @custom:selector 0x574a4cff
     */
    function facetFuncs() public pure virtual override(IFacet) returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IRateProvider.getRate.selector;
        funcs[1] = IERC4626RateProvider.erc4626Vault.selector;
    }
    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @notice Returns the full metadata tuple for this facet (name + interfaces + functions) as required by IFacet.
     * @return name The facet name.
     * @return interfaces The supported interface IDs.
     * @return functions The exposed function selectors.
     * @custom:signature facetMetadata()
     * @custom:selector 0xf10d7a75
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
// end::ERC4626RateProviderFacet[]
