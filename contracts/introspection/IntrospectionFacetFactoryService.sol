// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Vm} from "forge-std/Vm.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {IDiamondCutFacetDFPkg, DiamondCutFacetDFPkg} from "@crane/contracts/introspection/ERC2535/DiamondCutFacetDFPkg.sol";


library IntrospectionFacetFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    function deployERC165Facet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet erc165Facet) {
        erc165Facet = create3Factory.deployFacet(
            type(ERC165Facet).creationCode,
            abi.encode(type(ERC165Facet).name)._hash()
        );
        vm.label(address(erc165Facet), type(ERC165Facet).name);
    }

    function deployDiamondLoupeFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet diamondLoupeFacet) {
        diamondLoupeFacet = create3Factory.deployFacet(
            type(DiamondLoupeFacet).creationCode,
            abi.encode(type(DiamondLoupeFacet).name)._hash()
        );
        vm.label(address(diamondLoupeFacet), type(DiamondLoupeFacet).name);
    }

    function deployDiamondCutFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet diamondCutFacet) {
        diamondCutFacet = create3Factory.deployFacet(
            type(DiamondCutFacet).creationCode,
            abi.encode(type(DiamondCutFacet).name)._hash()
        );
        vm.label(address(diamondCutFacet), type(DiamondCutFacet).name);
    }

    function deployDiamondCutDFPkg(
        ICreate3Factory create3Factory,
        IFacet multiStepOwnableFacet,
        IFacet diamondCutFacet
    ) internal returns (IDiamondCutFacetDFPkg diamondCutDFPkg) {
        diamondCutDFPkg = IDiamondCutFacetDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(DiamondCutFacetDFPkg).creationCode,
                    abi.encode(
                        IDiamondCutFacetDFPkg.PkgInit({
                            diamondCutFacet: diamondCutFacet,
                            multiStepOwnableFacet: multiStepOwnableFacet
                        })
                    ),
                    abi.encode(type(DiamondCutFacetDFPkg).name)._hash()
                )
            )
        );
        vm.label(address(diamondCutDFPkg), type(DiamondCutFacetDFPkg).name);
    }
}
