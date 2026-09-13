// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

interface IERC20MintBurnOwnableOperableDFPkg {
    struct PkgInit {
        IFacet erc20Facet;
        IFacet erc5267Facet;
        IFacet erc2612Facet;
        IFacet erc20MintBurnOwnableFacet;
        IFacet mutiStepOwnableFacet;
        IFacet operableFacet;
        IDiamondPackageCallBackFactory diamondFactory;
    }

    struct PkgArgs {
        string name;
        string symbol;
        uint8 decimals;
        address owner;
        bytes32 optionalSalt;
    }

    function deployToken(string memory name, string memory symbol, uint8 decimals, address owner, bytes32 optionalSalt)
        external
        returns (address tokenAddress);
}
