// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {Create3Factory} from "@crane/contracts/factories/create3/Create3Factory.sol";
import {
    IDiamondPackageCallBackFactoryInit,
    DiamondPackageCallBackFactory
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";

library InitDevService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    function initEnv(address owner)
        internal
        returns (ICreate3Factory factory, IDiamondPackageCallBackFactory diamondFactory)
    {
        factory = initFactory(owner, keccak256(abi.encode(owner)));
        diamondFactory = initDiamondFactory(factory);
        factory.setDiamondPackageFactory(diamondFactory);
    }

    function initFactory(address owner, bytes32 salt) internal returns (ICreate3Factory factory) {
        factory = new Create3Factory{salt: salt}(owner);
        vm.label(address(factory), "Create3Factory");
    }

    function initDiamondFactory(ICreate3Factory factory)
        internal
        returns (IDiamondPackageCallBackFactory diamondFactory)
    {
        // console.log("DiamondPackageCallBackFactory nedds to be deployed.");
        // console.log("Deploying ERC165Facet");
        IFacet erc165Facet =
            factory.deployFacet(type(ERC165Facet).creationCode, abi.encode(type(ERC165Facet).name)._hash());
        vm.label(address(erc165Facet), "ERC165Facet");
        // console.log("Deployed ERC165Facet at ", address(erc165Facet));
        // console.log("Deploying DiamondLoupeFacet");
        IFacet diamondLoupeFacet =
            factory.deployFacet(type(DiamondLoupeFacet).creationCode, abi.encode(type(DiamondLoupeFacet).name)._hash());
        vm.label(address(diamondLoupeFacet), "DiamondLoupeFacet");
        // console.log("Deployed DiamondLoupeFacet at ", address(diamondLoupeFacet));
        // console.log("Deploying PostDeployAccountHookFacet");
        IFacet postDeployAccountHookFacet = factory.deployFacet(
            type(PostDeployAccountHookFacet).creationCode, abi.encode(type(PostDeployAccountHookFacet).name)._hash()
        );
        vm.label(address(postDeployAccountHookFacet), "PostDeployAccountHookFacet");
        // console.log("Deployed PostDeployAccountHookFacet at ", address(postDeployAccountHookFacet));
        // console.log("Deploying DiamondPackageCallBackFactory");
        diamondFactory = IDiamondPackageCallBackFactory(
            factory.create3WithArgs(
                type(DiamondPackageCallBackFactory).creationCode,
                abi.encode(
                    IDiamondPackageCallBackFactoryInit.InitArgs({
                        erc165Facet: erc165Facet,
                        diamondLoupeFacet: diamondLoupeFacet,
                        postDeployHookFacet: postDeployAccountHookFacet
                    })
                ),
                abi.encode(type(DiamondPackageCallBackFactory).name)._hash()
            )
        );
        vm.label(address(diamondFactory), "DiamondPackageCallBackFactory");
        // console.log("Deployed DiamondPackageCallBackFactory at ", address(diamondPackageFactory_));
    }
}
