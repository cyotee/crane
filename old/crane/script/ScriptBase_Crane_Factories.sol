// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

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
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {Creation} from "contracts/crane/utils/Creation.sol";
import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {ETHEREUM_MAIN} from "contracts/crane/constants/networks/ETHEREUM_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "contracts/crane/constants/networks/ETHEREUM_SEPOLIA.sol";
import {APE_CHAIN_MAIN} from "contracts/crane/constants/networks/APE_CHAIN_MAIN.sol";
import {APE_CHAIN_CURTIS} from "contracts/crane/constants/networks/APE_CHAIN_CURTIS.sol";
import {IDiamondPackageCallBackFactory} from "contracts/crane/interfaces/IDiamondPackageCallBackFactory.sol";

import {Create2CallBackFactory} from "contracts/crane/factories/create2/callback/Create2CallBackFactory.sol";
import {CallbackFactoryAwareFacet} from "contracts/crane/factories/create2/callback/CallbackFactoryAwareFacet.sol";
import {
    DiamondPackageCallBackFactory
} from "contracts/crane/factories/create2/callback/diamondPkg/DiamondPackageCallBackFactory.sol";
import {
    DiamondPackageFactoryAwareFacet
} from "contracts/crane/factories/create2/callback/diamondPkg/DiamondPackageCallbackFactoryAwareFacet.sol";

abstract contract ScriptBase_Crane_Factories is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
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

    bytes constant CREATE2_CALLBACK_FACTORY_INIT_CODE = type(Create2CallBackFactory).creationCode;
    bytes32 constant CREATE2_CALLBACK_FACTORY_INIT_CODE_HASH = keccak256(CREATE2_CALLBACK_FACTORY_INIT_CODE);
    bytes32 constant CREATE2_CALLBACK_FACTORY_SALT = keccak256(abi.encode(type(Create2CallBackFactory).name));

    /**
     * @notice Declares the Create2CallBackFactory for the `chainid`.
     * @param chainid The chain id for which to declare the factory.
     * @param factory_ The factory to declare.
     * @return true if the factory was declared.
     */
    function factory(uint256 chainid, Create2CallBackFactory factory_) public virtual returns (bool) {
        registerInstance(chainid, CREATE2_CALLBACK_FACTORY_INIT_CODE_HASH, address(factory_));
        declare(builderKey_Crane_Factories(), "factory", address(factory_));
        return true;
    }

    /**
     * @notice Declares the Create2CallBackFactory for the current chain.
     * @param factory_ The factory to declare.
     * @return true if the factory was declared.
     */
    function factory(Create2CallBackFactory factory_) public virtual returns (bool) {
        factory(block.chainid, factory_);
        return true;
    }

    /**
     * @notice Retrieves the Create2CallBackFactory for the `chainid`.
     * @param chainid The chain id for which to retrieve the factory.
     * @return factory_ The factory.
     */
    function factory(uint256 chainid) public view virtual returns (Create2CallBackFactory factory_) {
        factory_ = Create2CallBackFactory(chainInstance(chainid, CREATE2_CALLBACK_FACTORY_INIT_CODE_HASH));
    }

    /**
     * @notice Singleton factory for the Create2CallBackFactory.
     * @return factory_ The CREATE2 factory.
     */
    function factory() public virtual returns (Create2CallBackFactory factory_) {
        if (address(factory(block.chainid)) == address(0)) {
            factory_ = Create2CallBackFactory(
                abi.encodePacked(CREATE2_CALLBACK_FACTORY_INIT_CODE, abi.encode(owner())).
                    _create2(CREATE2_CALLBACK_FACTORY_SALT)
            );
            factory(factory_);
        }
        factory_ = factory(block.chainid);
        return factory_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        CallbackFactoryAwareFacet                       */
    /* ---------------------------------------------------------------------- */

    bytes constant CALLBACK_FACTORY_AWARE_FACET_INIT_CODE = type(CallbackFactoryAwareFacet).creationCode;
    bytes32 constant CALLBACK_FACTORY_AWARE_FACET_INIT_CODE_HASH = keccak256(CALLBACK_FACTORY_AWARE_FACET_INIT_CODE);
    bytes32 constant CALLBACK_FACTORY_AWARE_FACET_SALT = keccak256(abi.encode(type(CallbackFactoryAwareFacet).name));

    function callbackFactoryAwareFacet(uint256 chainid, CallbackFactoryAwareFacet instance_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, CALLBACK_FACTORY_AWARE_FACET_INIT_CODE_HASH, address(instance_));
        declare(builderKey_Crane_Factories(), "callbackFactoryAwareFacet", address(instance_));
        return true;
    }

    function callbackFactoryAwareFacet(CallbackFactoryAwareFacet instance_) public virtual returns (bool) {
        callbackFactoryAwareFacet(block.chainid, instance_);
        return true;
    }

    function callbackFactoryAwareFacet(uint256 chainid)
        public
        view
        virtual
        returns (CallbackFactoryAwareFacet instance_)
    {
        instance_ = CallbackFactoryAwareFacet(chainInstance(chainid, CALLBACK_FACTORY_AWARE_FACET_INIT_CODE_HASH));
        return instance_;
    }

    function callbackFactoryAwareFacet() public virtual returns (CallbackFactoryAwareFacet instance_) {
        if (address(callbackFactoryAwareFacet(block.chainid)) == address(0)) {
            instance_ = CallbackFactoryAwareFacet(
                factory().create3(CALLBACK_FACTORY_AWARE_FACET_INIT_CODE, "", CALLBACK_FACTORY_AWARE_FACET_SALT)
            );
            callbackFactoryAwareFacet(instance_);
        }
        instance_ = callbackFactoryAwareFacet(block.chainid);
        return instance_;
    }

    /* ---------------------------------------------------------------------- */
    /*                     IDiamondPackageCallBackFactory                     */
    /* ---------------------------------------------------------------------- */

    bytes constant DIAMOND_PACKAGE_FACTORY_INIT_CODE = type(DiamondPackageCallBackFactory).creationCode;
    bytes32 constant DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH = keccak256(DIAMOND_PACKAGE_FACTORY_INIT_CODE);
    bytes32 constant DIAMOND_PACKAGE_FACTORY_SALT = keccak256(abi.encode(type(DiamondPackageCallBackFactory).name));

    function diamondFactory(uint256 chainid, IDiamondPackageCallBackFactory diamondFactory_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH, address(diamondFactory_));
        declare(builderKey_Crane_Factories(), "diamondFactory", address(diamondFactory_));
        return true;
    }

    /**
     * @notice Declares the diamond factory for later use.
     * @param diamondFactory_ The diamond factory to declare.
     * @return true if the diamond factory was declared.
     */
    function diamondFactory(IDiamondPackageCallBackFactory diamondFactory_) public virtual returns (bool) {
        diamondFactory(block.chainid, diamondFactory_);
        return true;
    }

    function diamondFactory(uint256 chainid)
        public
        view
        virtual
        returns (IDiamondPackageCallBackFactory diamondFactory_)
    {
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
                    factory()
                        .create3(
                            DIAMOND_PACKAGE_FACTORY_INIT_CODE,
                            "",
                            DIAMOND_PACKAGE_FACTORY_SALT
                        )
                );
            }
            diamondFactory(diamondFactory_);
        }
        return diamondFactory(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                     DiamondPackageFactoryAwareFacet                    */
    /* ---------------------------------------------------------------------- */

    bytes constant DIAMOND_PACKAGE_FACTORY_AWARE_FACET_INIT_CODE = type(DiamondPackageFactoryAwareFacet).creationCode;
    bytes32 constant DIAMOND_PACKAGE_FACTORY_AWARE_FACET_INIT_CODE_HASH =
        keccak256(DIAMOND_PACKAGE_FACTORY_AWARE_FACET_INIT_CODE);
    bytes32 constant DIAMOND_PACKAGE_FACTORY_AWARE_FACET_SALT =
        keccak256(abi.encode(type(DiamondPackageFactoryAwareFacet).name));

    function diamondPackageFactoryAwareFacet(uint256 chainid, DiamondPackageFactoryAwareFacet instance_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, DIAMOND_PACKAGE_FACTORY_AWARE_FACET_INIT_CODE_HASH, address(instance_));
        declare(builderKey_Crane_Factories(), "diamondPackageFactoryAwareFacet", address(instance_));
        return true;
    }

    function diamondPackageFactoryAwareFacet(DiamondPackageFactoryAwareFacet instance_) public virtual returns (bool) {
        diamondPackageFactoryAwareFacet(block.chainid, instance_);
        return true;
    }

    function diamondPackageFactoryAwareFacet(uint256 chainid)
        public
        view
        virtual
        returns (DiamondPackageFactoryAwareFacet instance_)
    {
        instance_ = DiamondPackageFactoryAwareFacet(
            chainInstance(chainid, DIAMOND_PACKAGE_FACTORY_AWARE_FACET_INIT_CODE_HASH)
        );
        return instance_;
    }

    function diamondPackageFactoryAwareFacet() public virtual returns (DiamondPackageFactoryAwareFacet instance_) {
        if (address(diamondPackageFactoryAwareFacet(block.chainid)) == address(0)) {
            instance_ = DiamondPackageFactoryAwareFacet(
                factory()
                    .create3(
                        DIAMOND_PACKAGE_FACTORY_AWARE_FACET_INIT_CODE, "", DIAMOND_PACKAGE_FACTORY_AWARE_FACET_SALT
                    )
            );
            diamondPackageFactoryAwareFacet(instance_);
        }
        instance_ = diamondPackageFactoryAwareFacet(block.chainid);
        return instance_;
    }
}
