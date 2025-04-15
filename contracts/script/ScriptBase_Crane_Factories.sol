// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

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
import { BetterScript } from "./BetterScript.sol";
import { Creation } from "../utils/Creation.sol";
import { LOCAL } from "../constants/networks/LOCAL.sol";
import { ETHEREUM_MAIN } from "../constants/networks/ETHEREUM_MAIN.sol";
import { ETHEREUM_SEPOLIA } from "../constants/networks/ETHEREUM_SEPOLIA.sol";
import { APE_CHAIN_MAIN } from "../constants/networks/APE_CHAIN_MAIN.sol";
import { APE_CHAIN_CURTIS } from "../constants/networks/APE_CHAIN_CURTIS.sol";
import { IDiamondPackageCallBackFactory } from "../interfaces/IDiamondPackageCallBackFactory.sol";

contract ScriptBase_Crane_Factories
is
    // CommonBase,
    // ScriptBase,
    // StdChains,
    // StdCheatsSafe,
    // StdUtils,
    // Script,
    BetterScript
{

    using Creation for bytes;

    function builderKey_Crane_Factories() public pure returns (string memory) {
        return "crane_factories";
    }

    function run() public virtual {
        declare(vm.getLabel(address(factory())), address(factory()));
        declare(vm.getLabel(address(diamondFactory())), address(diamondFactory()));
    }

    /* ---------------------------------------------------------------------- */
    /*                         Create2CallBackFactory                         */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Declares the Create2CallBackFactory for the `chainid`.
     * @param chainid The chain id for which to declare the factory.
     * @param factory_ The factory to declare.
     * @return true if the factory was declared.
     */
    function factory(
        uint256 chainid,
        Create2CallBackFactory factory_
    ) public returns(bool) {
        registerInstance(chainid, CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE_HASH, address(factory_));
        declare(builderKey_Crane_Factories(), "factory", address(factory_));
        return true;
    }

    /**
     * @notice Declares the Create2CallBackFactory for the current chain.
     * @param factory_ The factory to declare.
     * @return true if the factory was declared.
     */
    function factory(Create2CallBackFactory factory_) public returns(bool) {
        factory(block.chainid, factory_);
        return true;
    }

    /**
     * @notice Retrieves the Create2CallBackFactory for the `chainid`.
     * @param chainid The chain id for which to retrieve the factory.
     * @return factory_ The factory.
     */
    function factory(uint256 chainid)
    public virtual view returns(Create2CallBackFactory factory_) {
        factory_ = Create2CallBackFactory(chainInstance(chainid, CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE_HASH));
    }

    /**
     * @notice Singleton factory for the Create2CallBackFactory.
     * @return factory_ The CREATE2 factory.
     */
    function factory()
    public virtual returns(Create2CallBackFactory factory_) {
        if(address(factory(block.chainid)) == address(0)) {
            factory_ = Create2CallBackFactory(CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE._create());
            factory(factory_);
        }
        factory_ = factory(block.chainid);
        return factory_;
    }

    /* ---------------------------------------------------------------------- */
    /*                     IDiamondPackageCallBackFactory                     */
    /* ---------------------------------------------------------------------- */

    function diamondFactory(
        uint256 chainid,
        IDiamondPackageCallBackFactory diamondFactory_
    ) public returns(bool) {
        registerInstance(chainid, DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH, address(diamondFactory_));
        declare(builderKey_Crane_Factories(), "diamondFactory", address(diamondFactory_));
        return true;
    }

    /**
     * @notice Declares the diamond factory for later use.
     * @param diamondFactory_ The diamond factory to declare.
     * @return true if the diamond factory was declared.
     */
    function diamondFactory(IDiamondPackageCallBackFactory diamondFactory_) public returns(bool) {
        diamondFactory(block.chainid, diamondFactory_);
        return true;
    }

    function diamondFactory(uint256 chainid)
    public virtual view returns(IDiamondPackageCallBackFactory diamondFactory_) {
        diamondFactory_ = IDiamondPackageCallBackFactory(chainInstance(chainid, DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH));
        return diamondFactory_;
    }

    /**
     * @notice A package based factory for deploying diamond proxies.
     * @return diamondFactory_ The diamond factory.
     */
    function diamondFactory() public virtual returns (IDiamondPackageCallBackFactory diamondFactory_) {
        if (address(diamondFactory(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                diamondFactory_ = IDiamondPackageCallBackFactory(APE_CHAIN_MAIN.CRANE_DIAMOND_FACTORY_V1);
                diamondFactory(diamondFactory_);
            } else {
                diamondFactory_ = DiamondPackageCallBackFactory(
                    factory().create3(
                        DIAMOND_PACKAGE_FACTORY_INIT_CODE,
                        "",
                        keccak256(abi.encode(type(DiamondPackageCallBackFactory).name))
                    )
                );
            }
            diamondFactory(diamondFactory_);
        }
        return diamondFactory(block.chainid);
    }

}