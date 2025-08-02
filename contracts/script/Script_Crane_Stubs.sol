// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {
    CommonBase,
    ScriptBase,
    TestBase
} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {
    StdCheatsSafe,
    StdCheats
} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import { Script } from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "../constants/CraneINITCODE.sol";
import { betterconsole as console } from "../utils/vm/foundry/tools/betterconsole.sol";
import { BetterScript } from "./BetterScript.sol";
import { ScriptBase_Crane_Factories } from "./ScriptBase_Crane_Factories.sol";
import { ScriptBase_Crane_ERC20 } from "./ScriptBase_Crane_ERC20.sol";
import { ScriptBase_Crane_ERC4626 } from "./ScriptBase_Crane_ERC4626.sol";
import { Script_Crane } from "./Script_Crane.sol";

contract Script_Crane_Stubs
is
    CommonBase,
    ScriptBase,

    StdChains,
    StdCheatsSafe,

    StdUtils,
    Script,
    BetterScript,

    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,

    Script_Crane
{

    function builderKey_CraneStubs() public pure returns (string memory) {
        return "craneStubs";
    }

    function run() public virtual
    override(
        ScriptBase_Crane_Factories,
        ScriptBase_Crane_ERC20,
        ScriptBase_Crane_ERC4626,
        Script_Crane
    ) {
        // ScriptBase_Crane_Factories.run();
        // ScriptBase_Crane_ERC20.run();
        // ScriptBase_Crane_ERC4626.run();
        Script_Crane.run();
    }

    /* ---------------------------------------------------------------------- */
    /*                              GreeterFacet                              */
    /* ---------------------------------------------------------------------- */

    function greeterFacet(
        uint256 chainid,
        GreeterFacet greeterFacet_
    ) public virtual returns(bool) {
        // console.log("Fixture_Crane:greeterFacet(uint256,GreeterFacet):: Entering function.");
        // console.log("Fixture_Crane:greeterFacet(uint256,GreeterFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane:greeterFacet(uint256,GreeterFacet):: Storing instance mapped to initCodeHash: %s.", GREETER_FACET_INIT_CODE_HASH);
        // console.log("Fixture_Crane:greeterFacet(uint256,GreeterFacet):: Instance to store: %s.", address(greeterFacet_));
        registerInstance(chainid, GREETER_FACET_INIT_CODE_HASH, address(greeterFacet_));
        declare(builderKey_CraneStubs(), "greeterFacet", address(greeterFacet_));
        // console.log("Fixture_Crane:greeterFacet(uint256,GreeterFacet):: Exiting function.");
        return true;
    }

    function greeterFacet(GreeterFacet greeterFacet_) public virtual returns(bool) {
        // console.log("Fixture_Crane:greeterFacet(GreeterFacet):: Entering function.");
        // console.log("Fixture_Crane:greeterFacet(GreeterFacet):: Setting provided greeter facet of %s", address(greeterFacet_));
        greeterFacet(block.chainid, greeterFacet_);
        // console.log("Fixture_Crane:greeterFacet(GreeterFacet):: Set address of GreeterFacet for later use.");
        // console.log("Fixture_Crane:greeterFacet(GreeterFacet):: Exiting function.");
        return true;
    }

    function greeterFacet(uint256 chainid)
    public virtual view returns(GreeterFacet greeterFacet_) {
        // console.log("Fixture_Crane:greeterFacet(uint256):: Entering function.");
        // console.log("Fixture_Crane:greeterFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane:greeterFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", GREETER_FACET_INIT_CODE_HASH);
        greeterFacet_ = GreeterFacet(chainInstance(chainid, GREETER_FACET_INIT_CODE_HASH));
        // console.log("Fixture_Crane:greeterFacet(uint256):: Instance retrieved: %s.", address(greeterFacet_));
        // console.log("Fixture_Crane:greeterFacet(uint256):: Exiting function.");
        return greeterFacet_;
    }

    function greeterFacet() public virtual returns (GreeterFacet greeterFacet_) {
        // console.log("Fixture_Crane:greeterFacet():: Entering function.");
        // console.log("Fixture_Crane:greeterFacet():: Checking if GreeterFacet is declared.");
        if (address(greeterFacet(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane:greeterFacet():: GreeterFacet is not declared, deploying...");
            greeterFacet_ = GreeterFacet(
                factory().create3(
                    GREETER_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(GreeterFacet).name))
                )
            );
            // console.log("Fixture_Crane:greeterFacet():: GreeterFacet deployed @ ", address(greeterFacet_));
            // console.log("Fixture_Crane:greeterFacet():: Setting greeter facet for later use.");
            greeterFacet(greeterFacet_);
            // console.log("Fixture_Crane:greeterFacet():: Greeter facet set for later use.");
        }
        // console.log("Fixture_Crane:greeterFacet():: Returning value from storage presuming it would have been set based on chain state.");
        greeterFacet_ = greeterFacet(block.chainid);
        // console.log("Fixture_Crane:greeterFacet():: Exiting function.");
        return greeterFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                    GreeterFacetDiamondFactoryPackage                   */
    /* ---------------------------------------------------------------------- */

    function greeterFacetDFPkg(
        uint256 chainid,
        GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_
    ) public virtual returns(bool) {
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256,GreeterFacetDiamondFactoryPackage):: Entering function.");
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256,GreeterFacetDiamondFactoryPackage):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256,GreeterFacetDiamondFactoryPackage):: Storing instance mapped to initCodeHash: %s.", GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH);
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256,GreeterFacetDiamondFactoryPackage):: Instance to store: %s.", address(greeterFacetDFPkg_));
        registerInstance(chainid, GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH, address(greeterFacetDFPkg_));
        declare(builderKey_CraneStubs(), "greeterFacetDFPkg", address(greeterFacetDFPkg_));
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256,GreeterFacetDiamondFactoryPackage):: Exiting function.");
        return true;
    }

    function greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) public virtual returns(bool) {
        // console.log("Fixture_Crane:greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage):: Entering function.");
        // console.log("Fixture_Crane:greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage):: Setting provided greeter facet diamond factory package of %s", address(greeterFacetDFPkg_));
        greeterFacetDFPkg(block.chainid, greeterFacetDFPkg_);
        // console.log("Fixture_Crane:greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage):: Set address of GreeterFacetDiamondFactoryPackage for later use.");
        // console.log("Fixture_Crane:greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage):: Exiting function.");
        return true;
    }

    function greeterFacetDFPkg(uint256 chainid)
    public virtual view returns(GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) {
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256):: Entering function.");
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256):: Retrieving instance mapped to initCodeHash: %s.", GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH);
        greeterFacetDFPkg_ = GreeterFacetDiamondFactoryPackage(chainInstance(chainid, GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH));
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256):: Instance retrieved: %s.", address(greeterFacetDFPkg_));
        // console.log("Fixture_Crane:greeterFacetDFPkg(uint256):: Exiting function.");
        return greeterFacetDFPkg_;
    }

    function greeterFacetDFPkg() public virtual returns (GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) {
        // console.log("Fixture_Crane:greeterFacetDFPkg():: Entering function.");
        // console.log("Fixture_Crane:greeterFacetDFPkg():: Checking if GreeterFacetDiamondFactoryPackage is declared.");
        if (address(greeterFacetDFPkg(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane:greeterFacetDFPkg():: GreeterFacetDiamondFactoryPackage is not declared, deploying...");
            greeterFacetDFPkg_ = GreeterFacetDiamondFactoryPackage(
                factory().create3(
                    GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(GreeterFacetDiamondFactoryPackage).name))
                )
            );
            // console.log("Fixture_Crane:greeterFacetDFPkg():: GreeterFacetDiamondFactoryPackage deployed @ ", address(greeterFacetDFPkg_));
            // console.log("Fixture_Crane:greeterFacetDFPkg():: Setting greeter facet diamond factory package for later use.");
            greeterFacetDFPkg(greeterFacetDFPkg_);
            // console.log("Fixture_Crane:greeterFacetDFPkg():: Greeter facet diamond factory package set for later use.");
        }
        // console.log("Fixture_Crane:greeterFacetDFPkg():: Returning value from storage presuming it would have been set based on chain state.");
        greeterFacetDFPkg_ = greeterFacetDFPkg(block.chainid);
        // console.log("Fixture_Crane:greeterFacetDFPkg():: Exiting function.");
        return greeterFacetDFPkg_;
    }

}