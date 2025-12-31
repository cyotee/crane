// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "contracts/crane/constants/CraneINITCODE.sol";
import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {ScriptBase_Crane_Factories} from "./ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "./ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "./ScriptBase_Crane_ERC4626.sol";
import {Script_Crane} from "./Script_Crane.sol";

abstract contract Script_Crane_Stubs is
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

    function run()
        public
        virtual
        override(ScriptBase_Crane_Factories, ScriptBase_Crane_ERC20, ScriptBase_Crane_ERC4626, Script_Crane)
    {
        // ScriptBase_Crane_Factories.run();
        // ScriptBase_Crane_ERC20.run();
        // ScriptBase_Crane_ERC4626.run();
        Script_Crane.run();
    }

    /* ---------------------------------------------------------------------- */
    /*                              GreeterFacet                              */
    /* ---------------------------------------------------------------------- */

    function greeterFacet(uint256 chainid, GreeterFacet greeterFacet_) public virtual returns (bool) {
        registerInstance(chainid, GREETER_FACET_INIT_CODE_HASH, address(greeterFacet_));
        declare(builderKey_CraneStubs(), "greeterFacet", address(greeterFacet_));
        return true;
    }

    function greeterFacet(GreeterFacet greeterFacet_) public virtual returns (bool) {
        greeterFacet(block.chainid, greeterFacet_);
        return true;
    }

    function greeterFacet(uint256 chainid) public view virtual returns (GreeterFacet greeterFacet_) {
        greeterFacet_ = GreeterFacet(chainInstance(chainid, GREETER_FACET_INIT_CODE_HASH));
        return greeterFacet_;
    }

    function greeterFacet() public virtual returns (GreeterFacet greeterFacet_) {
        if (address(greeterFacet(block.chainid)) == address(0)) {
            greeterFacet_ = GreeterFacet(
                factory().create3(GREETER_FACET_INIT_CODE, "", keccak256(abi.encode(type(GreeterFacet).name)))
            );
            greeterFacet(greeterFacet_);
        }
        greeterFacet_ = greeterFacet(block.chainid);
        return greeterFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                    GreeterFacetDiamondFactoryPackage                   */
    /* ---------------------------------------------------------------------- */

    function greeterFacetDFPkg(uint256 chainid, GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH, address(greeterFacetDFPkg_));
        declare(builderKey_CraneStubs(), "greeterFacetDFPkg", address(greeterFacetDFPkg_));
        return true;
    }

    function greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) public virtual returns (bool) {
        greeterFacetDFPkg(block.chainid, greeterFacetDFPkg_);
        return true;
    }

    function greeterFacetDFPkg(uint256 chainid)
        public
        view
        virtual
        returns (GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_)
    {
        greeterFacetDFPkg_ = GreeterFacetDiamondFactoryPackage(
            chainInstance(chainid, GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH)
        );
        return greeterFacetDFPkg_;
    }

    function greeterFacetDFPkg() public virtual returns (GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) {
        if (address(greeterFacetDFPkg(block.chainid)) == address(0)) {
            greeterFacetDFPkg_ = GreeterFacetDiamondFactoryPackage(
                factory()
                    .create3(
                        GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE,
                        "",
                        keccak256(abi.encode(type(GreeterFacetDiamondFactoryPackage).name))
                    )
            );
            greeterFacetDFPkg(greeterFacetDFPkg_);
        }
        greeterFacetDFPkg_ = greeterFacetDFPkg(block.chainid);
        return greeterFacetDFPkg_;
    }
}
