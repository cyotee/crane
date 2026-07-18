// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {Create3FactoryTarget} from "@crane/contracts/factories/create3/Create3FactoryTarget.sol";

// tag::Create3FactoryFacet[]
/**
 * @title Create3FactoryFacet - Diamond facet for CREATE3 deterministic deployments.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes ICreate3Factory functionality via the Diamond proxy pattern.
 *         This facet is bundled in the core Create3FactoryDFPkg.
 * @dev Delegates implementation to Create3FactoryTarget. Implements IFacet for
 *      declarative metadata used by registries and deployment tools.
 */
contract Create3FactoryFacet is Create3FactoryTarget, IFacet {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure returns (string memory name) {
        return type(Create3FactoryFacet).name;
    }

    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     * @dev Declares support for ICreate3Factory (see ICreate3Factory for its function selectors).
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICreate3Factory).interfaceId;
    }

    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = ICreate3Factory.diamondPackageFactory.selector;
        funcs[1] = ICreate3Factory.setDiamondPackageFactory.selector;
        funcs[2] = ICreate3Factory.create3.selector;
        funcs[3] = ICreate3Factory.create3WithArgs.selector;
    }

    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
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
// end::Create3FactoryFacet[]
