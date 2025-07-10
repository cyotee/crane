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
import { BetterScript } from "../script/BetterScript.sol";
import { ScriptBase_Crane_Factories } from "../script/ScriptBase_Crane_Factories.sol";
import { ScriptBase_Crane_ERC20 } from "../script/ScriptBase_Crane_ERC20.sol";
import { ScriptBase_Crane_ERC4626 } from "../script/ScriptBase_Crane_ERC4626.sol";
import {terminal as term} from "../utils/vm/foundry/tools/terminal.sol";
import { LOCAL } from "../constants/networks/LOCAL.sol";
import { ETHEREUM_MAIN } from "../constants/networks/ETHEREUM_MAIN.sol";
import { ETHEREUM_SEPOLIA } from "../constants/networks/ETHEREUM_SEPOLIA.sol";
import { APE_CHAIN_MAIN } from "../constants/networks/APE_CHAIN_MAIN.sol";
import { APE_CHAIN_CURTIS } from "../constants/networks/APE_CHAIN_CURTIS.sol";
import { Creation } from "../utils/Creation.sol";
import { ICreate2CallbackFactory } from "../interfaces/ICreate2CallbackFactory.sol";
import { Create2CallBackFactory } from "../factories/create2/callback/Create2CallBackFactory.sol";
import { IPower } from "../interfaces/IPower.sol";
import { PowerCalculatorC2ATarget } from "../utils/math/power-calc/PowerCalculatorC2ATarget.sol";
import { ICreate3Aware } from "../interfaces/ICreate3Aware.sol";
import {
    IERC20MintBurnOperableFacetDFPkg,
    ERC20MintBurnOperableFacetDFPkg
} from "../token/ERC20/extensions/ERC20MintBurnOperableFacetDFPkg.sol";
import { IUniswapV2Aware } from "../interfaces/IUniswapV2Aware.sol";
import { CamelotV2AwareFacet } from "../protocols/dexes/camelot/v2/CamelotV2AwareFacet.sol";
import { UniswapV2AwareFacet } from "../protocols/dexes/uniswap/v2/UniswapV2AwareFacet.sol";


import {
    AddressSet,
    AddressSetRepo
} from "../utils/collections/sets/AddressSetRepo.sol";
import {
    StringSet,
    StringSetRepo
} from "../utils/collections/sets/StringSetRepo.sol";


contract Script_Crane
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
    ScriptBase_Crane_ERC4626
{

    using AddressSetRepo for AddressSet;
    using Creation for bytes;
    using StringSetRepo for StringSet;

    /* ---------------------------------------------------------------------- */
    /*                                 Errors                                 */
    /* ---------------------------------------------------------------------- */

    error NoOwnerDeclared(address owner);
    error NotForProduction(string contractName, bytes32 initCodeHash);

    function builderKey_Crane() public pure returns (string memory) {
        return "crane";
    }

    function run() public virtual
    override(
        ScriptBase_Crane_Factories,
        ScriptBase_Crane_ERC20,
        ScriptBase_Crane_ERC4626
    ) {
        // ScriptBase_Crane_Factories.run();
        // ScriptBase_Crane_ERC20.run();
        ScriptBase_Crane_ERC4626.run();
        declare(vm.getLabel(address(ownableFacet())), address(ownableFacet()));
        declare(vm.getLabel(address(operableFacet())), address(operableFacet()));
        declare(vm.getLabel(address(reentrancyLockFacet())), address(reentrancyLockFacet()));
        declare(vm.getLabel(address(diamondCutFacetDFPkg())), address(diamondCutFacetDFPkg()));
        declare(vm.getLabel(address(powerCalculator())), address(powerCalculator()));
        declare(vm.getLabel(address(erc20MintBurnPkg())), address(erc20MintBurnPkg()));
        declare(vm.getLabel(address(uniswapV2AwareFacet())), address(uniswapV2AwareFacet()));
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                              OwnableFacet                              */
    /* ---------------------------------------------------------------------- */

    function ownableFacet(
        uint256 chainid,
        OwnableFacet ownableFacet_
    ) public returns(bool) {
        // console.log("Fixture_Crane_Access:ownableFacet(uint256,OwnableFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:ownableFacet(uint256,OwnableFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:ownableFacet(uint256,OwnableFacet):: Storing instance mapped to initCodeHash: %s.", OWNABLE_FACET_INIT_CODE_HASH);
        // console.log("Fixture_Crane_Access:ownableFacet(uint256,OwnableFacet):: Instance to store: %s.", address(ownableFacet_));
        registerInstance(chainid, OWNABLE_FACET_INIT_CODE_HASH, address(ownableFacet_));
        // console.log("Fixture_Crane_Access:ownableFacet(uint256,OwnableFacet):: Declaring instance.");
        declare(builderKey_Crane(), "ownableFacet", address(ownableFacet_));
        // console.log("Fixture_Crane_Access:ownableFacet(uint256,OwnableFacet):: Exiting function.");
        return true;
    }

    /**
     * @notice Declares the ownable facet for later use.
     * @param ownableFacet_ The ownable facet to declare.
     * @return true if the ownable facet was declared.
     */
    function ownableFacet(OwnableFacet ownableFacet_) public returns(bool) {
        // console.log("Fixture_Crane_Access:ownableFacet(OwnableFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:ownableFacet(OwnableFacet):: Setting provided ownable facet of %s.", address(ownableFacet_));
        ownableFacet(block.chainid, ownableFacet_);
        // console.log("Fixture_Crane_Access:ownableFacet(OwnableFacet):: Exiting function.");
        return true;
    }

    function ownableFacet(uint256 chainid)
    public virtual view returns(OwnableFacet ownableFacet_) {
        // console.log("Fixture_Crane_Access:ownableFacet(uint256):: Entering function.");
        // console.log("Fixture_Crane_Access:ownableFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:ownableFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", OWNABLE_FACET_INIT_CODE_HASH);
        ownableFacet_ = OwnableFacet(chainInstance(chainid, OWNABLE_FACET_INIT_CODE_HASH));
        // console.log("Fixture_Crane_Access:ownableFacet(uint256):: Instance retrieved: %s.", address(ownableFacet_));
        // console.log("Fixture_Crane_Access:ownableFacet(uint256):: Exiting function.");
        return ownableFacet_;
    }

    /**
     * @notice Ownable facet.
     * @notice Exposes IOwnable so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply ownable modifiers.
     * @return ownableFacet_ The ownable facet.
     */
    function ownableFacet() public returns (OwnableFacet ownableFacet_) {
        // console.log("Fixture_Crane_Access:ownableFacet():: Entering function.");
        // console.log("Fixture_Crane_Access:ownableFacet():: Checking if OwnableFacet is declared.");
        if (address(ownableFacet(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane_Access:ownableFacet():: OwnableFacet is not declared, deploying.");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // console.log("Fixture_Crane_Access:ownableFacet():: OwnableFacet is not declared, setting to APE_CHAIN_MAIN.CRANE_OWNABLE_FACET_V1 of %s.", APE_CHAIN_MAIN.CRANE_OWNABLE_FACET_V1);
                ownableFacet_ = OwnableFacet(APE_CHAIN_MAIN.CRANE_OWNABLE_FACET_V1);
            } else {
                // console.log("Fixture_Crane_Access:ownableFacet():: OwnableFacet is not declared, deploying.");
                ownableFacet_ = OwnableFacet(
                    factory().create3(
                        OWNABLE_FACET_INIT_CODE,
                        abi.encode(ICreate3Aware.CREATE3InitData({
                            salt: keccak256(abi.encode(type(OwnableFacet).name)),
                            initData: ""
                        })),
                        keccak256(abi.encode(type(OwnableFacet).name))
                    )
                );
            }
            // console.log("Fixture_Crane_Access:ownableFacet():: OwnableFacet declared @ %s.", address(ownableFacet_));
            // console.log("Fixture_Crane_Access:ownableFacet():: Setting ownable facet for later use.");
            ownableFacet(ownableFacet_);
            // console.log("Fixture_Crane_Access:ownableFacet():: Ownable facet set for later use.");
        }
        // console.log("Fixture_Crane_Access:ownableFacet():: Returning value from storage presuming it would have been set based on chain state.");
        ownableFacet_ = ownableFacet(block.chainid);
        // console.log("Fixture_Crane_Access:ownableFacet():: Exiting function.");
        return ownableFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                              OperableFacet                             */
    /* ---------------------------------------------------------------------- */

    function operableFacet(
        uint256 chainid,
        OperableFacet operableFacet_
    ) public returns(bool) {
        // console.log("Fixture_Crane_Access:operableFacet(uint256,OperableFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:operableFacet(uint256,OperableFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:operableFacet(uint256,OperableFacet):: Storing instance mapped to initCodeHash: %s.", OPERABLE_FACET_INIT_CODE_HASH);
        // console.log("Fixture_Crane_Access:operableFacet(uint256,OperableFacet):: Instance to store: %s.", address(operableFacet_));
        registerInstance(chainid, OPERABLE_FACET_INIT_CODE_HASH, address(operableFacet_));
        // console.log("Fixture_Crane_Access:operableFacet(uint256,OperableFacet):: Declaring instance.");
        declare(builderKey_Crane(), "operableFacet", address(operableFacet_));
        // console.log("Fixture_Crane_Access:operableFacet(uint256,OperableFacet):: Exiting function.");
        return true;
    }

    /** 
     * @notice Declares the operable facet for later use.
     * @param operableFacet_ The operable facet to declare.
     * @return true if the operable facet was declared.
     */
    function operableFacet(OperableFacet operableFacet_) public returns(bool) {
        // console.log("Fixture_Crane_Access:operableFacet(OperableFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:operableFacet(OperableFacet):: Setting provided operable facet of %s.", address(operableFacet_));
        operableFacet(block.chainid, operableFacet_);
        // console.log("Fixture_Crane_Access:operableFacet(OperableFacet):: Exiting function.");
        return true;
    }

    function operableFacet(uint256 chainid)
    public virtual view returns(OperableFacet operableFacet_) {
        // console.log("Fixture_Crane_Access:operableFacet(uint256):: Entering function.");
        // console.log("Fixture_Crane_Access:operableFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:operableFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", OPERABLE_FACET_INIT_CODE_HASH);
        operableFacet_ = OperableFacet(chainInstance(chainid, OPERABLE_FACET_INIT_CODE_HASH));
        // console.log("Fixture_Crane_Access:operableFacet(uint256):: Instance retrieved: %s.", address(operableFacet_));
        // console.log("Fixture_Crane_Access:operableFacet(uint256):: Exiting function.");
        return operableFacet_;
    }

    /**
     * @notice Operable facet.
     * @notice Exposes IOperable so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply operable modifiers.
     * @return operableFacet_ The operable facet.
     */
    function operableFacet() public returns (OperableFacet operableFacet_) {
        // console.log("Fixture_Crane_Access:operableFacet():: Entering function.");
        // console.log("Fixture_Crane_Access:operableFacet():: Checking if OperableFacet is declared.");
        if (address(operableFacet(block.chainid)) == address(0)) {    
            // console.log("Fixture_Crane_Access:operableFacet():: OperableFacet is not declared, deploying.");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // console.log("Fixture_Crane_Access:operableFacet():: OperableFacet is not declared, setting to APE_CHAIN_MAIN.CRANE_OPERABLE_FACET_V1 of %s.", APE_CHAIN_MAIN.CRANE_OPERABLE_FACET_V1);
                operableFacet_ = OperableFacet(APE_CHAIN_MAIN.CRANE_OPERABLE_FACET_V1);
            } else {
                // console.log("Fixture_Crane_Access:operableFacet():: OperableFacet is not declared, deploying.");
                operableFacet_ = OperableFacet(
                    factory().create3(
                        OPERABLE_FACET_INIT_CODE,
                        abi.encode(ICreate3Aware.CREATE3InitData({
                            salt: keccak256(abi.encode(type(OperableFacet).name)),
                            initData: ""
                        })),
                        keccak256(abi.encode(type(OperableFacet).name))
                    )
                );
            }
            // console.log("Fixture_Crane_Access:operableFacet():: OperableFacet declared @ %s.", address(operableFacet_));
            // console.log("Fixture_Crane_Access:operableFacet():: Setting operable facet for later use.");
            operableFacet(operableFacet_);
            // console.log("Fixture_Crane_Access:operableFacet():: Operable facet set for later use.");
        }
        // console.log("Fixture_Crane_Access:operableFacet():: Returning value from storage presuming it would have been set based on chain state.");
        // console.log("Fixture_Crane_Access:operableFacet():: Exiting function.");
        return operableFacet(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                          OperableManagerFacet                          */
    /* ---------------------------------------------------------------------- */

    function operableManagerFacet(
        uint256 chainid,
        OperableManagerFacet operableManagerFacet_
    ) public returns(bool) {
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256,OperableManagerFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256,OperableManagerFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256,OperableManagerFacet):: Storing instance mapped to initCodeHash: %s.", OPERABLE_MANAGER_FACET_INITCODE_HASH);
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256,OperableManagerFacet):: Instance to store: %s.", address(operableManagerFacet_));
        registerInstance(chainid, OPERABLE_MANAGER_FACET_INITCODE_HASH, address(operableManagerFacet_));
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256,OperableManagerFacet):: Declaring instance.");
        declare(builderKey_Crane(), "operableManagerFacet", address(operableManagerFacet_));
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256,OperableManagerFacet):: Exiting function.");
        return true;
    }

    function operableManagerFacet(OperableManagerFacet operableManagerFacet_) public returns(bool) {
        // console.log("Fixture_Crane_Access:operableManagerFacet(OperableManagerFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:operableManagerFacet(OperableManagerFacet):: Setting provided operable manager facet of %s.", address(operableManagerFacet_));
        operableManagerFacet(block.chainid, operableManagerFacet_);
        // console.log("Fixture_Crane_Access:operableManagerFacet(OperableManagerFacet):: Exiting function.");
        return true;
    }

    function operableManagerFacet(uint256 chainid)
    public virtual view returns(OperableManagerFacet operableManagerFacet_) {
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256):: Entering function.");
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", OPERABLE_MANAGER_FACET_INITCODE_HASH);
        operableManagerFacet_ = OperableManagerFacet(chainInstance(chainid, OPERABLE_MANAGER_FACET_INITCODE_HASH));
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256):: Instance retrieved: %s.", address(operableManagerFacet_));
        // console.log("Fixture_Crane_Access:operableManagerFacet(uint256):: Exiting function.");
        return operableManagerFacet_;
    }

    function operableManagerFacet() public returns(OperableManagerFacet operableManagerFacet_) {
        // console.log("Fixture_Crane_Access:operableManagerFacet():: Entering function.");
        // console.log("Fixture_Crane_Access:operableManagerFacet():: Checking if OperableManagerFacet is declared.");
        if (address(operableManagerFacet(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane_Access:operableManagerFacet():: OperableManagerFacet is not declared, deploying.");
            // console.log("Fixture_Crane_Access:operableManagerFacet():: Deploying OperableManagerFacet.");
            operableManagerFacet_ = OperableManagerFacet(
                factory().create3(
                    OPERABLE_MANAGER_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(OperableManagerFacet).name))
                )
            );
            // console.log("Fixture_Crane_Access:operableManagerFacet():: OperableManagerFacet deployed @ %s.", address(operableManagerFacet_));
            // console.log("Fixture_Crane_Access:operableManagerFacet():: Setting operable manager facet for later use.");
            operableManagerFacet(operableManagerFacet_);
            // console.log("Fixture_Crane_Access:operableManagerFacet():: Operable manager facet set for later use.");
        }
        // console.log("Fixture_Crane_Access:operableManagerFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        operableManagerFacet_ = operableManagerFacet(block.chainid);
        // console.log("Fixture_Crane_Access:operableManagerFacet():: Returning value from storage presuming it would have been set based on chain state.");
        // console.log("Fixture_Crane_Access:operableManagerFacet():: Exiting function.");
        return operableManagerFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                           ReentrancyLockFacet                          */
    /* ---------------------------------------------------------------------- */

    function reentrancyLockFacet(
        uint256 chainid,
        ReentrancyLockFacet reentrancyLockFacet_
    ) public returns(bool) {
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256,ReentrancyLockFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256,ReentrancyLockFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256,ReentrancyLockFacet):: Storing instance mapped to initCodeHash: %s.", REENTRANCY_LOCK_FACET_INIT_CODE_HASH);
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256,ReentrancyLockFacet):: Instance to store: %s.", address(reentrancyLockFacet_));
        registerInstance(chainid, REENTRANCY_LOCK_FACET_INIT_CODE_HASH, address(reentrancyLockFacet_));
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256,ReentrancyLockFacet):: Declaring instance.");
        declare(builderKey_Crane(), "reentrancyLockFacet", address(reentrancyLockFacet_));
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256,ReentrancyLockFacet):: Exiting function.");
        return true;
    }

    /** 
     * @notice Declares the reentrancy lock facet for later use.
     * @param reentrancyLockFacet_ The reentrancy lock facet to declare.
     * @return true if the reentrancy lock facet was declared.
     */
    function reentrancyLockFacet(ReentrancyLockFacet reentrancyLockFacet_) public returns(bool) {
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(ReentrancyLockFacet):: Entering function.");
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(ReentrancyLockFacet):: Setting provided reentrancy lock facet of %s.", address(reentrancyLockFacet_));
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(ReentrancyLockFacet):: Declaring address of ReentrancyLockFacet.");
        reentrancyLockFacet(block.chainid, reentrancyLockFacet_);
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(ReentrancyLockFacet):: Declared address of ReentrancyLockFacet.");
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(ReentrancyLockFacet):: Exiting function.");
        return true;
    }   

    function reentrancyLockFacet(uint256 chainid)
    public virtual view returns(ReentrancyLockFacet reentrancyLockFacet_) {
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256):: Entering function.");
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", REENTRANCY_LOCK_FACET_INIT_CODE_HASH);
        reentrancyLockFacet_ = ReentrancyLockFacet(chainInstance(chainid, REENTRANCY_LOCK_FACET_INIT_CODE_HASH));
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256):: Instance retrieved: %s.", address(reentrancyLockFacet_));
        // console.log("Fixture_Crane_Access:reentrancyLockFacet(uint256):: Exiting function.");
    }

    /**
     * @notice Reentrancy lock facet.
     * @notice Exposes IReentrancyLock so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply reentrancy lock modifiers.
     * @return reentrancyLockFacet_ The reentrancy lock facet.
     */
    function reentrancyLockFacet() public returns (ReentrancyLockFacet reentrancyLockFacet_) {
        // console.log("Fixture_Crane_Access:reentrancyLockFacet():: Entering function.");
        // console.log("Fixture_Crane_Access:reentrancyLockFacet():: Checking if ReentrancyLockFacet is declared.");
        if (address(reentrancyLockFacet(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane_Access:reentrancyLockFacet():: ReentrancyLockFacet is not declared, deploying.");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // console.log("Fixture_Crane_Access:reentrancyLockFacet():: ReentrancyLockFacet is not declared, setting to APE_CHAIN_MAIN.CRANE_REENTRANCY_LOCK_FACET_V1 of %s.", APE_CHAIN_MAIN.CRANE_REENTRANCY_LOCK_FACET_V1);
                reentrancyLockFacet_ = ReentrancyLockFacet(APE_CHAIN_MAIN.CRANE_REENTRANCY_LOCK_FACET_V1);
            } else {
                // console.log("Fixture_Crane_Access:reentrancyLockFacet():: ReentrancyLockFacet is not declared, deploying.");
                reentrancyLockFacet_ = ReentrancyLockFacet(
                    factory().create3(
                        REENTRANCY_LOCK_FACET_INIT_CODE,
                        abi.encode(ICreate3Aware.CREATE3InitData({
                            salt: keccak256(abi.encode(type(ReentrancyLockFacet).name)),
                            initData: ""
                        })),
                        keccak256(abi.encode(type(ReentrancyLockFacet).name))
                    )
                );
            }
            // console.log("Fixture_Crane_Access:reentrancyLockFacet():: ReentrancyLockFacet declared @ %s.", address(reentrancyLockFacet_));
            // console.log("Fixture_Crane_Access:reentrancyLockFacet():: Setting reentrancy lock facet for later use.");
            reentrancyLockFacet(reentrancyLockFacet_);
            // console.log("Fixture_Crane_Access:reentrancyLockFacet():: Reentrancy lock facet set for later use.");
        }
        // console.log("Fixture_Crane_Access:reentrancyLockFacet():: Returning value from storage presuming it would have been set based on chain state.");
        // console.log("Fixture_Crane_Access:reentrancyLockFacet():: Exiting function.");
        return reentrancyLockFacet(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                          DiamondCutFacetDFPkg                          */
    /* ---------------------------------------------------------------------- */

    function diamondCutFacetDFPkg(
        uint256 chainid,
        DiamondCutFacetDFPkg diamondCutFacetDFPkg_
    ) public returns(bool) {
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256,DiamondCutFacetDFPkg):: Entering function.");
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256,DiamondCutFacetDFPkg):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256,DiamondCutFacetDFPkg):: Storing instance mapped to initCodeHash: %s.", DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH);
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256,DiamondCutFacetDFPkg):: Instance to store: %s.", address(diamondCutFacetDFPkg_));
        registerInstance(chainid, DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH, address(diamondCutFacetDFPkg_));
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256,DiamondCutFacetDFPkg):: Declaring instance.");
        declare(builderKey_Crane(), "diamondCutFacetDFPkg", address(diamondCutFacetDFPkg_));
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256,DiamondCutFacetDFPkg):: Exiting function.");
        return true;
    }

    function diamondCutFacetDFPkg(DiamondCutFacetDFPkg diamondCutFacetDFPkg_) public returns(bool) {
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(DiamondCutFacetDFPkg):: Entering function.");
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(DiamondCutFacetDFPkg):: Setting provided diamond cut facet diamond factory package of %s", address(diamondCutFacetDFPkg_));
        diamondCutFacetDFPkg(block.chainid, diamondCutFacetDFPkg_);
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(DiamondCutFacetDFPkg):: Set address of DiamondCutFacetDFPkg for later use.");
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(DiamondCutFacetDFPkg):: Exiting function.");
        return true;
    }

    function diamondCutFacetDFPkg(uint256 chainid)
    public virtual view returns(DiamondCutFacetDFPkg diamondCutFacetDFPkg_) {
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256):: Entering function.");
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256):: Retrieving instance mapped to initCodeHash: %s.", DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH);
        diamondCutFacetDFPkg_ = DiamondCutFacetDFPkg(chainInstance(chainid, DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH));
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256):: Instance retrieved: %s.", address(diamondCutFacetDFPkg_));
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg(uint256):: Exiting function.");
        return diamondCutFacetDFPkg_;
    }

    function diamondCutFacetDFPkg() public returns (DiamondCutFacetDFPkg diamondCutFacetDFPkg_) {
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Entering function.");
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Checking if DiamondCutFacetDFPkg is declared.");
        if (address(diamondCutFacetDFPkg(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: DiamondCutFacetDFPkg is not declared, deploying.");
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Setting Package initialization arguments.");
            DiamondCutFacetDFPkg.DiamondCutPkgInit memory diamondCutPkgInit;
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Setting ownableFacet to ", address(ownableFacet()));
            diamondCutPkgInit.ownableFacet = ownableFacet();
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Deploying DiamondCutFacetDFPkg.");
            diamondCutFacetDFPkg_ = DiamondCutFacetDFPkg(
                factory().create3(
                    DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE,
                    abi.encode(diamondCutPkgInit),
                    keccak256(abi.encode(type(DiamondCutFacetDFPkg).name))
                )
            );
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: DiamondCutFacetDFPkg deployed @ ", address(diamondCutFacetDFPkg_));
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Setting diamond cut facet diamond factory package for later use.");
            diamondCutFacetDFPkg(diamondCutFacetDFPkg_);
            // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Diamond cut facet diamond factory package set for later use.");
        }
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Returning value from storage presuming it would have been set based on chain state.");
        diamondCutFacetDFPkg_ = diamondCutFacetDFPkg(block.chainid);
        // console.log("Fixture_Crane_Upgradable:diamondCutFacetDFPkg():: Exiting function.");
        return diamondCutFacetDFPkg_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        PowerCalculatorC2ATarget                        */
    /* ---------------------------------------------------------------------- */

    function powerCalculator(
        uint256 chainid,
        PowerCalculatorC2ATarget powerCalculator_
    ) public returns(bool) {
        // console.log("Fixture_Crane_Math:powerCalculator(uint256,PowerCalculatorC2ATarget):: Entering function.");
        // console.log("Fixture_Crane_Math:powerCalculator(uint256,PowerCalculatorC2ATarget):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Math:powerCalculator(uint256,PowerCalculatorC2ATarget):: Storing instance mapped to initCodeHash: %s.", POWER_CALC_INIT_CODE_HASH);
        // console.log("Fixture_Crane_Math:powerCalculator(uint256,PowerCalculatorC2ATarget):: Instance to store: %s.", address(powerCalculator_));
        registerInstance(chainid, POWER_CALC_INIT_CODE_HASH, address(powerCalculator_));
        // console.log("Fixture_Crane_Math:powerCalculator(uint256,PowerCalculatorC2ATarget):: Declaring instance.");
        declare(builderKey_Crane(), "powerCalculator", address(powerCalculator_));
        // console.log("Fixture_Crane_Math:powerCalculator(uint256,PowerCalculatorC2ATarget):: Exiting function.");
        return true;
    }

    /** 
     * @notice Declares the power calculator for later use.
     * @param powerCalculator_ The power calculator to declare.
     * @return true if the power calculator was declared.
     */
    function powerCalculator(PowerCalculatorC2ATarget powerCalculator_) public returns(bool) {
        // console.log("Fixture_Crane_Math:powerCalculator(PowerCalculatorC2ATarget):: Entering function.");
        // console.log("Fixture_Crane_Math:powerCalculator(PowerCalculatorC2ATarget):: Setting provided power calculator of %s.", address(powerCalculator_));
        powerCalculator(block.chainid, powerCalculator_);
        // console.log("Fixture_Crane_Math:powerCalculator(PowerCalculatorC2ATarget):: Declaring address of PowerCalculatorC2ATarget.");
        // console.log("Fixture_Crane_Math:powerCalculator(PowerCalculatorC2ATarget):: Exiting function.");
        return true;
    }

    function powerCalculator(uint256 chainid)
    public virtual view returns(PowerCalculatorC2ATarget powerCalculator_) {
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Entering function.");
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Retrieving instance mapped to initCodeHash: %s.", POWER_CALC_INIT_CODE_HASH);
        powerCalculator_ = PowerCalculatorC2ATarget(chainInstance(chainid, POWER_CALC_INIT_CODE_HASH));
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Instance retrieved: %s.", address(powerCalculator_));
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Exiting function.");
        return powerCalculator_;
    }

    /**
     * @notice Power calculator.
     * @notice Does gas efficient power calculations.
     * @notice Externalized to save bytecode size.
     * @return powerCalculator_ The power calculator.    
     */
    function powerCalculator()
    public virtual returns(PowerCalculatorC2ATarget powerCalculator_) {
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Entering function.");
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Checking if PowerCalculatorC2ATarget is declared.");
        if(address(powerCalculator(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane_Math:powerCalculator(uint256):: PowerCalculatorC2ATarget is not declared, setting");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // console.log("Fixture_Crane_Math:powerCalculator(uint256):: PowerCalculatorC2ATarget is not declared, setting to APE_CHAIN_MAIN.CRANE_POWER_CALCULATOR_V1 of %s.", APE_CHAIN_MAIN.CRANE_POWER_CALCULATOR_V1);
                powerCalculator_ = PowerCalculatorC2ATarget(APE_CHAIN_MAIN.CRANE_POWER_CALCULATOR_V1);
            } else {
                // console.log("Fixture_Crane_Math:powerCalculator(uint256):: PowerCalculatorC2ATarget is not declared, deploying.");
                powerCalculator_ = PowerCalculatorC2ATarget(
                    factory().create3(
                        POWER_CALC_INIT_CODE,
                        "",
                        keccak256(abi.encode(type(PowerCalculatorC2ATarget).name))
                    )
                );
            }
            // console.log("Fixture_Crane_Math:powerCalculator(uint256):: PowerCalculatorC2ATarget declared @ %s.", address(powerCalculator_));
            // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Setting power calculator for later use.");
            powerCalculator(powerCalculator_);
            // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Power calculator set for later use.");
        }
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Returning value from storage presuming it would have been set based on chain state.");
        powerCalculator_ = powerCalculator(block.chainid);
        // console.log("Fixture_Crane_Math:powerCalculator(uint256):: Exiting function.");
        return powerCalculator_;
    }

    /* ---------------------------------------------------------------------- */
    /*                     ERC20MintBurnOperableFacetDFPkg                    */
    /* ---------------------------------------------------------------------- */

    function erc20MintBurnPkg(
        uint256 chainid,
        ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_
    ) public returns(bool) {
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256,ERC20MintBurnOperableFacetDFPkg):: Entering function.");
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256,ERC20MintBurnOperableFacetDFPkg):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256,ERC20MintBurnOperableFacetDFPkg):: Storing instance mapped to initCodeHash: %s.", ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH);
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256,ERC20MintBurnOperableFacetDFPkg):: Instance to store: %s.", address(erc20MintBurnPkg_));
        registerInstance(chainid, ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH, address(erc20MintBurnPkg_));
        declare(builderKey_Crane(), "erc20MintBurnPkg", address(erc20MintBurnPkg_));
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256,ERC20MintBurnOperableFacetDFPkg):: Exiting function.");
        return true;
    }

    /**
     * @notice Declares the ERC20 mint burn operable facet diamond factory package for later use.
     * @param erc20MintBurnPkg_ The ERC20 mint burn operable facet diamond factory package to declare.
     * @return true if the ERC20 mint burn operable facet diamond factory package was declared.
     */
    function erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) public returns(bool) {
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg):: Entering function.");   
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg):: Setting provided ERC20 mint burn operable facet diamond factory package of %s", address(erc20MintBurnPkg_));
        erc20MintBurnPkg(block.chainid, erc20MintBurnPkg_);
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg):: Set address of ERC20MintBurnOperableFacetDFPkg for later use.");
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg):: Exiting function.");
        return true;
    }

    function erc20MintBurnPkg(uint256 chainid)
    public virtual view returns(ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) {
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256):: Entering function.");
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256):: Retrieving instance mapped to initCodeHash: %s.", ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH);
        erc20MintBurnPkg_ = ERC20MintBurnOperableFacetDFPkg(chainInstance(chainid, ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH));
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256):: Instance retrieved: %s.", address(erc20MintBurnPkg_));
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg(uint256):: Exiting function.");
        return erc20MintBurnPkg_;
    }

    /**
     * @notice ERC20 mint burn operable facet diamond factory package.
     * @notice Deploys a DiamondFactorPackage for deploying ERC20MintBurnOperableFacet proxies.
     * @return erc20MintBurnPkg_ The ERC20 mint burn operable facet diamond factor package.
     */
    function erc20MintBurnPkg() public returns (ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) {
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Entering function.");
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Checking if ERC20MintBurnOperableFacetDFPkg is declared.");
        if (address(erc20MintBurnPkg(block.chainid)) == address(0)) {
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: ERC20MintBurnOperableFacetDFPkg is not declared, deploying.");
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Setting Package initialization arguments.");
            ERC20MintBurnOperableFacetDFPkg
                .PkgInit memory erc20MintPkgInit;
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Setting ownableFacet to ", address(ownableFacet()));
            erc20MintPkgInit.ownableFacet = ownableFacet();
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Setting operableFacet to ", address(operableFacet()));
            erc20MintPkgInit.operableFacet = operableFacet();
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Setting erc20PermitFacet to ", address(erc20PermitFacet()));
            erc20MintPkgInit.erc20PermitFacet = erc20PermitFacet();

            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Deploying ERC20MintBurnOperableFacetDFPkg.");
            erc20MintBurnPkg_ = ERC20MintBurnOperableFacetDFPkg(
                factory().create3(
                    ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE,
                    abi.encode(
                        IERC20MintBurnOperableFacetDFPkg.PkgInit({
                            ownableFacet: ownableFacet(),
                            operableFacet: operableFacet(),
                            erc20PermitFacet: erc20PermitFacet()
                        })
                    ),
                    keccak256(abi.encode(type(ERC20MintBurnOperableFacetDFPkg).name))
                )
            );
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: ERC20MintBurnOperableFacetDFPkg deployed @ ", address(erc20MintBurnPkg_));
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Setting ERC20 mint burn operable facet diamond factory package for later use.");
            erc20MintBurnPkg(erc20MintBurnPkg_);
            // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: ERC20 mint burn operable facet diamond factory package set for later use.");
        }
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Returning value from storage presuming it would have been set based on chain state.");
        erc20MintBurnPkg_ = erc20MintBurnPkg(block.chainid);
        // console.log("Fixture_Crane_ERC20:erc20MintBurnPkg():: Exiting function.");
        return erc20MintBurnPkg_;
    }

    /* ---------------------------------------------------------------------- */
    /*                           CamelotV2AwareFacet                          */
    /* ---------------------------------------------------------------------- */

    function camelotV2AwareFacet(
        uint256 chainid,
        CamelotV2AwareFacet camelotV2Aware_
    ) public returns(bool) {
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256,CamelotV2AwareFacet):: Entering function.");
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256,CamelotV2AwareFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256,CamelotV2AwareFacet):: Storing instance mapped to initCodeHash: %s.", CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH);
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256,CamelotV2AwareFacet):: Instance to store: %s.", address(camelotV2Aware_));
        registerInstance(chainid, CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH, address(camelotV2Aware_));
        declare(builderKey_Crane(), "camelotV2AwareFacet", address(camelotV2Aware_));
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256,CamelotV2AwareFacet):: Exiting function.");
        return true;
    }

    function camelotV2AwareFacet(CamelotV2AwareFacet camelotV2Aware_) public returns(bool) {
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(CamelotV2AwareFacet):: Entering function.");
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(CamelotV2AwareFacet):: Setting provided camelot v2 aware facet of %s.", address(camelotV2Aware_));
        camelotV2AwareFacet(block.chainid, camelotV2Aware_);
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(CamelotV2AwareFacet):: Exiting function.");
        return true;
    }

    function camelotV2AwareFacet(uint256 chainid) public view returns(CamelotV2AwareFacet camelotV2AwareFacet_) {
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256):: Entering function.");
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH);
        camelotV2AwareFacet_ = CamelotV2AwareFacet(chainInstance(chainid, CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH));
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256):: Instance retrieved: %s.", address(camelotV2AwareFacet_));
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256):: Exiting function.");
        return camelotV2AwareFacet_;
    }

    function camelotV2AwareFacet() public returns(CamelotV2AwareFacet camelotV2AwareFacet_) {
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Entering function.");
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(camelotV2AwareFacet(block.chainid)) == address(0)) {
            // console.log("CamelotV2AwareFacet not set on this chain, setting");
            // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Creating instance.");
            camelotV2AwareFacet_ = CamelotV2AwareFacet(
                factory().create3(
                    CAMELOT_V2_AWARE_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(CamelotV2AwareFacet).name))
                )
            );
            // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Instance created: %s.", address(camelotV2AwareFacet_));
            // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Storing instance.");
            camelotV2AwareFacet(block.chainid, camelotV2AwareFacet_);
        }
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        camelotV2AwareFacet_ = camelotV2AwareFacet(block.chainid);
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Instance retrieved: %s.", address(camelotV2AwareFacet_));
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet():: Exiting function.");
        return camelotV2AwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                           UniswapV2AwareFacet                          */
    /* ---------------------------------------------------------------------- */

    function uniswapV2AwareFacet(
        uint256 chainid,
        UniswapV2AwareFacet uniswapV2Aware_
    ) public returns(bool) {
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256,UniswapV2AwareFacet):: Entering function.");
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256,UniswapV2AwareFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256,UniswapV2AwareFacet):: Storing instance mapped to initCodeHash: %s.", UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH);
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256,UniswapV2AwareFacet):: Instance to store: %s.", address(uniswapV2Aware_));
        registerInstance(chainid, UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH, address(uniswapV2Aware_));
        declare(builderKey_Crane(), "uniswapV2AwareFacet", address(uniswapV2Aware_));
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256,UniswapV2AwareFacet):: Exiting function.");
        return true;
    }

    function uniswapV2AwareFacet(UniswapV2AwareFacet uniswapV2Aware_) public returns(bool) {
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(UniswapV2AwareFacet):: Entering function.");
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(UniswapV2AwareFacet):: Setting provided uniswap v2 aware facet of %s.", address(uniswapV2Aware_));
        uniswapV2AwareFacet(block.chainid, uniswapV2Aware_);
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(UniswapV2AwareFacet):: Exiting function.");
        return true;
    }

    function uniswapV2AwareFacet(uint256 chainid) public view returns(UniswapV2AwareFacet) {
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256):: Entering function.");
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH);
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet(uint256):: Exiting function.");
        return UniswapV2AwareFacet(chainInstance(chainid, UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH));
    }

    function uniswapV2AwareFacet() public returns(UniswapV2AwareFacet uniswapV2Aware_) {
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet():: Entering function.");
        if(address(uniswapV2AwareFacet(block.chainid)) == address(0)) {
            // console.log("UniswapV2AwareFacet not set on this chain, setting");
            // console.log("Fixture_UniswapV2:uniswapV2AwareFacet():: Deploying UniswapV2AwareFacet.");
            uniswapV2Aware_ = UniswapV2AwareFacet(
                factory().create3(
                    UNISWAP_V2_AWARE_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(UniswapV2AwareFacet).name))
                )
            );
            // console.log("Fixture_UniswapV2:uniswapV2AwareFacet():: UniswapV2AwareFacet deployed @ ", address(uniswapV2Aware_));
            // console.log("Fixture_UniswapV2:uniswapV2AwareFacet():: Setting uniswap v2 aware facet for later use.");
            uniswapV2AwareFacet(block.chainid, uniswapV2Aware_);
        }
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet():: Returning value from storage presuming it would have been set based on chain state.");
        uniswapV2Aware_ = uniswapV2AwareFacet(block.chainid);
        // console.log("Fixture_UniswapV2:uniswapV2AwareFacet():: Exiting function.");
        return uniswapV2Aware_;
    }
    
    /* ---------------------------------------------------------------------- */
    /*                        BalancerV3VaultAwareFacet                       */
    /* ---------------------------------------------------------------------- */

    function balancerV3VaultAwareFacet(
        uint256 chainid,
        BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256,BalancerV3VaultAwareFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256,BalancerV3VaultAwareFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256,BalancerV3VaultAwareFacet):: Storing instance mapped to initCodeHash: %s.", BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256,BalancerV3VaultAwareFacet):: Instance to store: %s.", address(balancerV3VaultAwareFacet_));
        registerInstance(chainid, BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH, address(balancerV3VaultAwareFacet_));
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256,BalancerV3VaultAwareFacet):: Declaring instance.");
        declare(builderKey_Crane(), "balancerV3VaultAwareFacet", address(balancerV3VaultAwareFacet_));
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256,BalancerV3VaultAwareFacet):: Exiting function.");
        return true;
    }

    function balancerV3VaultAwareFacet(BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_) public returns(bool) {
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(BalancerV3VaultAwareFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(BalancerV3VaultAwareFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(BalancerV3VaultAwareFacet):: Instance to store: %s.", address(balancerV3VaultAwareFacet_));
        balancerV3VaultAwareFacet(block.chainid, balancerV3VaultAwareFacet_);
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(BalancerV3VaultAwareFacet):: Exiting function.");
        return true;
    }

    function balancerV3VaultAwareFacet(uint256 chainid) public view returns(BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_) {
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH);
        balancerV3VaultAwareFacet_ = BalancerV3VaultAwareFacet(chainInstance(chainid, BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256):: Instance retrieved: %s.", address(balancerV3VaultAwareFacet_));
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet(uint256):: Exiting function.");
        return balancerV3VaultAwareFacet_;
    }

    function balancerV3VaultAwareFacet() public returns(BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_) {
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Entering function.");
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(balancerV3VaultAwareFacet(block.chainid)) == address(0)) {
            // console.log("BalancerV3VaultAwareFacet not set on this chain, setting");
            // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Creating instance.");
            balancerV3VaultAwareFacet_ = BalancerV3VaultAwareFacet(
                factory().create3(
                    BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(BalancerV3VaultAwareFacet).name))
                )
            );
            // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Instance created: %s.", address(balancerV3VaultAwareFacet_));
            // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Storing instance.");
            balancerV3VaultAwareFacet(block.chainid, balancerV3VaultAwareFacet_);
        }
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        balancerV3VaultAwareFacet_ = balancerV3VaultAwareFacet(block.chainid);
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Instance retrieved: %s.", address(balancerV3VaultAwareFacet_));
        // console.log("IndexedexFixture:balancerV3VaultAwareFacet():: Exiting function.");
        return balancerV3VaultAwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                     BetterBalancerV3PoolTokenFacet                     */
    /* ---------------------------------------------------------------------- */

    function betterBalancerV3PoolTokenFacet(
        uint256 chainid,
        BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256,BetterBalancerV3PoolTokenFacet):: Entering function.");
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256,BetterBalancerV3PoolTokenFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256,BetterBalancerV3PoolTokenFacet):: Storing instance mapped to initCodeHash: %s.", BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256,BetterBalancerV3PoolTokenFacet):: Instance to store: %s.", address(betterBalancerV3PoolTokenFacet_));
        registerInstance(chainid, BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH, address(betterBalancerV3PoolTokenFacet_));
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256,BetterBalancerV3PoolTokenFacet):: Declaring instance.");
        declare(builderKey_Crane(), "betterBalancerV3PoolTokenFacet", address(betterBalancerV3PoolTokenFacet_));
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256,BetterBalancerV3PoolTokenFacet):: Exiting function.");
        return true;
    }

    function betterBalancerV3PoolTokenFacet(BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_) public returns(bool) {
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(BetterBalancerV3PoolTokenFacet):: Entering function.");
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(BetterBalancerV3PoolTokenFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(BetterBalancerV3PoolTokenFacet):: Instance to store: %s.", address(betterBalancerV3PoolTokenFacet_));
        betterBalancerV3PoolTokenFacet(block.chainid, betterBalancerV3PoolTokenFacet_);
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(BetterBalancerV3PoolTokenFacet):: Exiting function.");
        return true;
    }

    function betterBalancerV3PoolTokenFacet(uint256 chainid) public view returns(BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_) {
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH);
        betterBalancerV3PoolTokenFacet_ = BetterBalancerV3PoolTokenFacet(chainInstance(chainid, BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256):: Instance retrieved: %s.", address(betterBalancerV3PoolTokenFacet_));
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet(uint256):: Exiting function.");
        return betterBalancerV3PoolTokenFacet_;
    }

    function betterBalancerV3PoolTokenFacet() public returns(BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_) {
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Entering function.");
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(betterBalancerV3PoolTokenFacet(block.chainid)) == address(0)) {
            // console.log("BetterBalancerV3PoolTokenFacet not set on this chain, setting");
            // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Creating instance.");
            betterBalancerV3PoolTokenFacet_ = BetterBalancerV3PoolTokenFacet(
                factory().create3(
                    BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(BetterBalancerV3PoolTokenFacet).name))
                )
            );
            // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Instance created: %s.", address(betterBalancerV3PoolTokenFacet_));
            // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Storing instance.");
            betterBalancerV3PoolTokenFacet(block.chainid, betterBalancerV3PoolTokenFacet_);
        }
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        betterBalancerV3PoolTokenFacet_ = betterBalancerV3PoolTokenFacet(block.chainid);
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Instance retrieved: %s.", address(betterBalancerV3PoolTokenFacet_));
        // console.log("IndexedexFixture:betterBalancerV3PoolTokenFacet():: Exiting function.");
        return betterBalancerV3PoolTokenFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                      BalancerV3AuthenticationFacet                     */
    /* ---------------------------------------------------------------------- */

    function balancerV3AuthenticationFacet(
        uint256 chainid,
        BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256,BalancerV3AuthenticationFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256,BalancerV3AuthenticationFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256,BalancerV3AuthenticationFacet):: Storing instance mapped to initCodeHash: %s.", BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256,BalancerV3AuthenticationFacet):: Instance to store: %s.", address(balancerV3AuthenticationFacet_));
        registerInstance(chainid, BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH, address(balancerV3AuthenticationFacet_));
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256,BalancerV3AuthenticationFacet):: Declaring instance.");
        declare(builderKey_Crane(), "balancerV3AuthenticationFacet", address(balancerV3AuthenticationFacet_));
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256,BalancerV3AuthenticationFacet):: Exiting function.");
        return true;
    }

    function balancerV3AuthenticationFacet(BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_) public returns(bool) {
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(BalancerV3AuthenticationFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(BalancerV3AuthenticationFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(BalancerV3AuthenticationFacet):: Instance to store: %s.", address(balancerV3AuthenticationFacet_));
        balancerV3AuthenticationFacet(block.chainid, balancerV3AuthenticationFacet_);
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(BalancerV3AuthenticationFacet):: Exiting function.");
        return true;
    }

    function balancerV3AuthenticationFacet(uint256 chainid) public view returns(BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_) {
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH);
        balancerV3AuthenticationFacet_ = BalancerV3AuthenticationFacet(chainInstance(chainid, BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256):: Instance retrieved: %s.", address(balancerV3AuthenticationFacet_));
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet(uint256):: Exiting function.");
        return balancerV3AuthenticationFacet_;
    }

    function balancerV3AuthenticationFacet() public returns(BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_) {
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Entering function.");
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(balancerV3AuthenticationFacet(block.chainid)) == address(0)) {
            // console.log("BalancerV3AuthenticationFacet not set on this chain, setting");
            // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Creating instance.");
            balancerV3AuthenticationFacet_ = BalancerV3AuthenticationFacet(
                factory().create3(
                    BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(BalancerV3AuthenticationFacet).name))
                )
            );
            // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Instance created: %s.", address(balancerV3AuthenticationFacet_));
            // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Storing instance.");
            balancerV3AuthenticationFacet(block.chainid, balancerV3AuthenticationFacet_);
        }
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        balancerV3AuthenticationFacet_ = balancerV3AuthenticationFacet(block.chainid);
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Instance retrieved: %s.", address(balancerV3AuthenticationFacet_));
        // console.log("IndexedexFixture:balancerV3AuthenticationFacet():: Exiting function.");
        return balancerV3AuthenticationFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*               BalancedLiquidityInvariantRatioBoundsFacet               */
    /* ---------------------------------------------------------------------- */

    function balancedLiquidityInvariantRatioBoundsFacet(
        uint256 chainid,
        BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256,BalancedLiquidityInvariantRatioBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256,BalancedLiquidityInvariantRatioBoundsFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256,BalancedLiquidityInvariantRatioBoundsFacet):: Storing instance mapped to initCodeHash: %s.", BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256,BalancedLiquidityInvariantRatioBoundsFacet):: Instance to store: %s.", address(balancedLiquidityInvariantRatioBoundsFacet_));
        registerInstance(chainid, BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH, address(balancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256,BalancedLiquidityInvariantRatioBoundsFacet):: Declaring instance.");
        declare(builderKey_Crane(), "balancedLiquidityInvariantRatioBoundsFacet", address(balancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256,BalancedLiquidityInvariantRatioBoundsFacet):: Exiting function.");
        return true;
    }

    function balancedLiquidityInvariantRatioBoundsFacet(BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_) public returns(bool) {
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(BalancedLiquidityInvariantRatioBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(BalancedLiquidityInvariantRatioBoundsFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(BalancedLiquidityInvariantRatioBoundsFacet):: Instance to store: %s.", address(balancedLiquidityInvariantRatioBoundsFacet_));
        balancedLiquidityInvariantRatioBoundsFacet(block.chainid, balancedLiquidityInvariantRatioBoundsFacet_);
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(BalancedLiquidityInvariantRatioBoundsFacet):: Exiting function.");
        return true;
    }

    function balancedLiquidityInvariantRatioBoundsFacet(uint256 chainid) public view returns(BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_) {
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH);
        balancedLiquidityInvariantRatioBoundsFacet_ = BalancedLiquidityInvariantRatioBoundsFacet(chainInstance(chainid, BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256):: Instance retrieved: %s.", address(balancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet(uint256):: Exiting function.");
        return balancedLiquidityInvariantRatioBoundsFacet_;
    }

    function balancedLiquidityInvariantRatioBoundsFacet() public returns(BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_) {
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Entering function.");
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(balancedLiquidityInvariantRatioBoundsFacet(block.chainid)) == address(0)) {
            // console.log("BalancedLiquidityInvariantRatioBoundsFacet not set on this chain, setting");
            // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Creating instance.");
            balancedLiquidityInvariantRatioBoundsFacet_ = BalancedLiquidityInvariantRatioBoundsFacet(
                factory().create3(
                    BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(BalancedLiquidityInvariantRatioBoundsFacet).name))
                )
            );
            // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Instance created: %s.", address(balancedLiquidityInvariantRatioBoundsFacet_));
            // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Storing instance.");
            balancedLiquidityInvariantRatioBoundsFacet(block.chainid, balancedLiquidityInvariantRatioBoundsFacet_);
        }
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        balancedLiquidityInvariantRatioBoundsFacet_ = balancedLiquidityInvariantRatioBoundsFacet(block.chainid);
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Instance retrieved: %s.", address(balancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:balancedLiquidityInvariantRatioBoundsFacet():: Exiting function.");
        return balancedLiquidityInvariantRatioBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                  StandardSwapFeePercentageBoundsFacet                  */
    /* ---------------------------------------------------------------------- */

    function standardSwapFeePercentageBoundsFacet(
        uint256 chainid,
        StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256,StandardSwapFeePercentageBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256,StandardSwapFeePercentageBoundsFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256,StandardSwapFeePercentageBoundsFacet):: Storing instance mapped to initCodeHash: %s.", STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256,StandardSwapFeePercentageBoundsFacet):: Instance to store: %s.", address(standardSwapFeePercentageBoundsFacet_));
        registerInstance(chainid, STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH, address(standardSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256,StandardSwapFeePercentageBoundsFacet):: Declaring instance.");
        declare(builderKey_Crane(), "standardSwapFeePercentageBoundsFacet", address(standardSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256,StandardSwapFeePercentageBoundsFacet):: Exiting function.");
        return true;
    }

    function standardSwapFeePercentageBoundsFacet(StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_) public returns(bool) {
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(StandardSwapFeePercentageBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(StandardSwapFeePercentageBoundsFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(StandardSwapFeePercentageBoundsFacet):: Instance to store: %s.", address(standardSwapFeePercentageBoundsFacet_));
        standardSwapFeePercentageBoundsFacet(block.chainid, standardSwapFeePercentageBoundsFacet_);
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(StandardSwapFeePercentageBoundsFacet):: Exiting function.");
        return true;
    }

    function standardSwapFeePercentageBoundsFacet(uint256 chainid) public view returns(StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_) {
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH);
        standardSwapFeePercentageBoundsFacet_ = StandardSwapFeePercentageBoundsFacet(chainInstance(chainid, STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256):: Instance retrieved: %s.", address(standardSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet(uint256):: Exiting function.");
        return standardSwapFeePercentageBoundsFacet_;
    }

    function standardSwapFeePercentageBoundsFacet() public returns(StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_) {
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Entering function.");
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(standardSwapFeePercentageBoundsFacet(block.chainid)) == address(0)) {
            // console.log("StandardSwapFeePercentageBoundsFacet not set on this chain, setting");
            // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Creating instance.");
            standardSwapFeePercentageBoundsFacet_ = StandardSwapFeePercentageBoundsFacet(
                factory().create3(
                    STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(StandardSwapFeePercentageBoundsFacet).name))
                )
            );
            // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Instance created: %s.", address(standardSwapFeePercentageBoundsFacet_));
            // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Storing instance.");
            standardSwapFeePercentageBoundsFacet(block.chainid, standardSwapFeePercentageBoundsFacet_);
        }
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        standardSwapFeePercentageBoundsFacet_ = standardSwapFeePercentageBoundsFacet(block.chainid);
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Instance retrieved: %s.", address(standardSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:standardSwapFeePercentageBoundsFacet():: Exiting function.");
        return standardSwapFeePercentageBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*          StandardUnbalancedLiquidityInvariantRatioBoundsFacet          */
    /* ---------------------------------------------------------------------- */

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet(
        uint256 chainid,
        StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256,StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256,StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256,StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Storing instance mapped to initCodeHash: %s.", STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256,StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Instance to store: %s.", address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
        registerInstance(chainid, STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH, address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256,StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Declaring instance.");
        declare(builderKey_Crane(), "standardUnbalancedLiquidityInvariantRatioBoundsFacet", address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256,StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Exiting function.");
        return true;
    }

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet(StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_) public returns(bool) {
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Instance to store: %s.", address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
        standardUnbalancedLiquidityInvariantRatioBoundsFacet(block.chainid, standardUnbalancedLiquidityInvariantRatioBoundsFacet_);
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(StandardUnbalancedLiquidityInvariantRatioBoundsFacet):: Exiting function.");
        return true;
    }

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256 chainid) public view returns(StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_) {
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH);
        standardUnbalancedLiquidityInvariantRatioBoundsFacet_ = StandardUnbalancedLiquidityInvariantRatioBoundsFacet(chainInstance(chainid, STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256):: Instance retrieved: %s.", address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256):: Exiting function.");
        return standardUnbalancedLiquidityInvariantRatioBoundsFacet_;
    }

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet() public returns(StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_) {
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Entering function.");
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(standardUnbalancedLiquidityInvariantRatioBoundsFacet(block.chainid)) == address(0)) {
            // console.log("StandardUnbalancedLiquidityInvariantRatioBoundsFacet not set on this chain, setting");
            // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Creating instance.");
            standardUnbalancedLiquidityInvariantRatioBoundsFacet_ = StandardUnbalancedLiquidityInvariantRatioBoundsFacet(
                factory().create3(
                    STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(StandardUnbalancedLiquidityInvariantRatioBoundsFacet).name))
                )
            );
            // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Instance created: %s.", address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
            // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Storing instance.");
            standardUnbalancedLiquidityInvariantRatioBoundsFacet(block.chainid, standardUnbalancedLiquidityInvariantRatioBoundsFacet_);
        }
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        standardUnbalancedLiquidityInvariantRatioBoundsFacet_ = standardUnbalancedLiquidityInvariantRatioBoundsFacet(block.chainid);
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Instance retrieved: %s.", address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_));
        // console.log("IndexedexFixture:standardUnbalancedLiquidityInvariantRatioBoundsFacet():: Exiting function.");
        return standardUnbalancedLiquidityInvariantRatioBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                    ZeroSwapFeePercentageBoundsFacet                    */
    /* ---------------------------------------------------------------------- */

    function zeroSwapFeePercentageBoundsFacet(
        uint256 chainid,
        ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_
    ) public returns(bool) {
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256,ZeroSwapFeePercentageBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256,ZeroSwapFeePercentageBoundsFacet):: Storing instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256,ZeroSwapFeePercentageBoundsFacet):: Storing instance mapped to initCodeHash: %s.", ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH);
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256,ZeroSwapFeePercentageBoundsFacet):: Instance to store: %s.", address(zeroSwapFeePercentageBoundsFacet_));
        registerInstance(chainid, ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH, address(zeroSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256,ZeroSwapFeePercentageBoundsFacet):: Declaring instance.");
        declare(builderKey_Crane(), "zeroSwapFeePercentageBoundsFacet", address(zeroSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256,ZeroSwapFeePercentageBoundsFacet):: Exiting function.");
        return true;
    }

    function zeroSwapFeePercentageBoundsFacet(ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_) public returns(bool) {
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(ZeroSwapFeePercentageBoundsFacet):: Entering function.");
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(ZeroSwapFeePercentageBoundsFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(ZeroSwapFeePercentageBoundsFacet):: Instance to store: %s.", address(zeroSwapFeePercentageBoundsFacet_));
        zeroSwapFeePercentageBoundsFacet(block.chainid, zeroSwapFeePercentageBoundsFacet_);
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(ZeroSwapFeePercentageBoundsFacet):: Exiting function.");
        return true;
    }

    function zeroSwapFeePercentageBoundsFacet(uint256 chainid) public view returns(ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_) {
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256):: Retrieving instance mapped to chainId %s.", chainid);
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH);
        zeroSwapFeePercentageBoundsFacet_ = ZeroSwapFeePercentageBoundsFacet(chainInstance(chainid, ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH));
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256):: Instance retrieved: %s.", address(zeroSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet(uint256):: Exiting function.");
        return zeroSwapFeePercentageBoundsFacet_;
    }

    function zeroSwapFeePercentageBoundsFacet() public returns(ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_) {
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Entering function.");
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(zeroSwapFeePercentageBoundsFacet(block.chainid)) == address(0)) {
            // console.log("ZeroSwapFeePercentageBoundsFacet not set on this chain, setting");
            // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Creating instance.");
            zeroSwapFeePercentageBoundsFacet_ = ZeroSwapFeePercentageBoundsFacet(
                factory().create3(
                    ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE,
                    "",
                    keccak256(abi.encode(type(ZeroSwapFeePercentageBoundsFacet).name))
                )
            );
            // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Instance created: %s.", address(zeroSwapFeePercentageBoundsFacet_));
            // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Storing instance.");
            zeroSwapFeePercentageBoundsFacet(block.chainid, zeroSwapFeePercentageBoundsFacet_);
        }
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        zeroSwapFeePercentageBoundsFacet_ = zeroSwapFeePercentageBoundsFacet(block.chainid);
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Instance retrieved: %s.", address(zeroSwapFeePercentageBoundsFacet_));
        // console.log("IndexedexFixture:zeroSwapFeePercentageBoundsFacet():: Exiting function.");
        return zeroSwapFeePercentageBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                          DefaultPoolInfoFacet                          */
    /* ---------------------------------------------------------------------- */

    function defaultPoolInfoFacet(
        uint256 chainId,
        DefaultPoolInfoFacet defaultPoolInfoFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256,DefaultPoolInfoFacet):: Entering function.");
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256,DefaultPoolInfoFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256,DefaultPoolInfoFacet):: Storing instance mapped to initCodeHash: %s.", DEFAULT_POOL_INFO_FACET_INITCODE);
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256,DefaultPoolInfoFacet):: Instance to store: %s.", address(defaultPoolInfoFacet_));
        registerInstance(chainId, DEFAULT_POOL_INFO_FACET_INITCODE_HASH, address(defaultPoolInfoFacet_));
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256,DefaultPoolInfoFacet):: Declaring instance.");
        declare(builderKey_Crane(), "defaultPoolInfoFacet", address(defaultPoolInfoFacet_));
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256,DefaultPoolInfoFacet):: Exiting function.");
        return true;
    }

    function defaultPoolInfoFacet(DefaultPoolInfoFacet defaultPoolInfoFacet_) public returns (bool) {
        // console.log("IndexedexFixture:defaultPoolInfoFacet(DefaultPoolInfoFacet):: Entering function.");
        // console.log("IndexedexFixture:defaultPoolInfoFacet(DefaultPoolInfoFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:defaultPoolInfoFacet(DefaultPoolInfoFacet):: Instance to store: %s.", address(defaultPoolInfoFacet_));
        defaultPoolInfoFacet(block.chainid, defaultPoolInfoFacet_);
        // console.log("IndexedexFixture:defaultPoolInfoFacet(DefaultPoolInfoFacet):: Exiting function.");
        return true;
    }

    function defaultPoolInfoFacet(uint256 chainId) public view returns (DefaultPoolInfoFacet defaultPoolInfoFacet_) {
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", DEFAULT_POOL_INFO_FACET_INITCODE);
        defaultPoolInfoFacet_ = DefaultPoolInfoFacet(chainInstance(chainId, DEFAULT_POOL_INFO_FACET_INITCODE_HASH));
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256):: Instance retrieved: %s.", address(defaultPoolInfoFacet_));
        // console.log("IndexedexFixture:defaultPoolInfoFacet(uint256):: Exiting function.");
        return defaultPoolInfoFacet_;
    }

    function defaultPoolInfoFacet() public returns (DefaultPoolInfoFacet defaultPoolInfoFacet_) {
        // console.log("IndexedexFixture:defaultPoolInfoFacet():: Entering function.");
        // console.log("IndexedexFixture:defaultPoolInfoFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(defaultPoolInfoFacet(block.chainid)) == address(0)) {
            // console.log("DefaultPoolInfoFacet not set on this chain, setting");
            // console.log("IndexedexFixture:defaultPoolInfoFacet():: Creating instance.");
            defaultPoolInfoFacet_ = DefaultPoolInfoFacet(
                factory().create3(
                    DEFAULT_POOL_INFO_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(DefaultPoolInfoFacet).name))
                )
            );
            // console.log("IndexedexFixture:defaultPoolInfoFacet():: Instance created: %s.", address(defaultPoolInfoFacet_));
            // console.log("IndexedexFixture:defaultPoolInfoFacet():: Storing instance.");
            defaultPoolInfoFacet(block.chainid, defaultPoolInfoFacet_);
        }
        // console.log("IndexedexFixture:defaultPoolInfoFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        defaultPoolInfoFacet_ = defaultPoolInfoFacet(block.chainid);
        // console.log("IndexedexFixture:defaultPoolInfoFacet():: Instance retrieved: %s.", address(defaultPoolInfoFacet_));
        // console.log("IndexedexFixture:defaultPoolInfoFacet():: Exiting function.");
        return defaultPoolInfoFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                    BalancerV3ERC4626AdaptorPoolFacet                   */
    /* ---------------------------------------------------------------------- */

    function balancerV3ERC4626AdaptorPoolFacet(
        uint256 chainId,
        BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256,BalancerV3ERC4626AdaptorPoolFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256,BalancerV3ERC4626AdaptorPoolFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256,BalancerV3ERC4626AdaptorPoolFacet):: Storing instance mapped to initCodeHash: %s.", BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256,BalancerV3ERC4626AdaptorPoolFacet):: Instance to store: %s.", address(balancerV3ERC4626AdaptorPoolFacet_));
        registerInstance(chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH, address(balancerV3ERC4626AdaptorPoolFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256,BalancerV3ERC4626AdaptorPoolFacet):: Declaring instance.");
        declare(builderKey_Crane(), "balancerV3ERC4626AdaptorPoolFacet", address(balancerV3ERC4626AdaptorPoolFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256,BalancerV3ERC4626AdaptorPoolFacet):: Exiting function.");
        return true;
    }

    function balancerV3ERC4626AdaptorPoolFacet(BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_) public returns (bool) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(BalancerV3ERC4626AdaptorPoolFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(BalancerV3ERC4626AdaptorPoolFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(BalancerV3ERC4626AdaptorPoolFacet):: Instance to store: %s.", address(balancerV3ERC4626AdaptorPoolFacet_));
        balancerV3ERC4626AdaptorPoolFacet(block.chainid, balancerV3ERC4626AdaptorPoolFacet_);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(BalancerV3ERC4626AdaptorPoolFacet):: Exiting function.");
        return true;
    }

    function balancerV3ERC4626AdaptorPoolFacet(uint256 chainId) public view returns (BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH);
        balancerV3ERC4626AdaptorPoolFacet_ = BalancerV3ERC4626AdaptorPoolFacet(chainInstance(chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256):: Instance retrieved: %s.", address(balancerV3ERC4626AdaptorPoolFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet(uint256):: Exiting function.");
        return balancerV3ERC4626AdaptorPoolFacet_;
    }

    function balancerV3ERC4626AdaptorPoolFacet() public returns (BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(balancerV3ERC4626AdaptorPoolFacet(block.chainid)) == address(0)) {
            // console.log("BalancerV3ERC4626AdaptorPoolFacet not set on this chain, setting");
            // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Creating instance.");
            balancerV3ERC4626AdaptorPoolFacet_ = BalancerV3ERC4626AdaptorPoolFacet(
                factory().create3(
                    BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(BalancerV3ERC4626AdaptorPoolFacet).name))
                )
            );
            // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Instance created: %s.", address(balancerV3ERC4626AdaptorPoolFacet_));
            // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Storing instance.");
            balancerV3ERC4626AdaptorPoolFacet(block.chainid, balancerV3ERC4626AdaptorPoolFacet_);
        }
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        balancerV3ERC4626AdaptorPoolFacet_ = balancerV3ERC4626AdaptorPoolFacet(block.chainid);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Instance retrieved: %s.", address(balancerV3ERC4626AdaptorPoolFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolFacet():: Exiting function.");
        return balancerV3ERC4626AdaptorPoolFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                 BalancerV3ERC4626AdaptorPoolHooksFacet                 */
    /* ---------------------------------------------------------------------- */

    function balancerV3ERC4626AdaptorPoolHooksFacet(
        uint256 chainId,
        BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256,BalancerV3ERC4626AdaptorPoolHooksFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256,BalancerV3ERC4626AdaptorPoolHooksFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256,BalancerV3ERC4626AdaptorPoolHooksFacet):: Storing instance mapped to initCodeHash: %s.", BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256,BalancerV3ERC4626AdaptorPoolHooksFacet):: Instance to store: %s.", address(balancerV3ERC4626AdaptorPoolHooksFacet_));
        registerInstance(chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH, address(balancerV3ERC4626AdaptorPoolHooksFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256,BalancerV3ERC4626AdaptorPoolHooksFacet):: Declaring instance.");
        declare(builderKey_Crane(), "balancerV3ERC4626AdaptorPoolHooksFacet", address(balancerV3ERC4626AdaptorPoolHooksFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256,BalancerV3ERC4626AdaptorPoolHooksFacet):: Exiting function.");
        return true;
    }

    function balancerV3ERC4626AdaptorPoolHooksFacet(BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_) public returns (bool) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(BalancerV3ERC4626AdaptorPoolHooksFacet):: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(BalancerV3ERC4626AdaptorPoolHooksFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(BalancerV3ERC4626AdaptorPoolHooksFacet):: Instance to store: %s.", address(balancerV3ERC4626AdaptorPoolHooksFacet_));
        balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid, balancerV3ERC4626AdaptorPoolHooksFacet_);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(BalancerV3ERC4626AdaptorPoolHooksFacet):: Exiting function.");
        return true;
    }

    function balancerV3ERC4626AdaptorPoolHooksFacet(uint256 chainId) public view returns (BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH);
        balancerV3ERC4626AdaptorPoolHooksFacet_ = BalancerV3ERC4626AdaptorPoolHooksFacet(chainInstance(chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256):: Instance retrieved: %s.", address(balancerV3ERC4626AdaptorPoolHooksFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet(uint256):: Exiting function.");
        return balancerV3ERC4626AdaptorPoolHooksFacet_;
    }

    function balancerV3ERC4626AdaptorPoolHooksFacet() public returns (BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_) {
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Entering function.");
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid)) == address(0)) {
            // console.log("BalancerV3ERC4626AdaptorPoolHooksFacet not set on this chain, setting");
            // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Creating instance.");
            balancerV3ERC4626AdaptorPoolHooksFacet_ = BalancerV3ERC4626AdaptorPoolHooksFacet(
                factory().create3(
                    BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(BalancerV3ERC4626AdaptorPoolHooksFacet).name))
                )
            );
            // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Instance created: %s.", address(balancerV3ERC4626AdaptorPoolHooksFacet_));
            // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Storing instance.");
            balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid, balancerV3ERC4626AdaptorPoolHooksFacet_);
        }
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        balancerV3ERC4626AdaptorPoolHooksFacet_ = balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid);
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Instance retrieved: %s.", address(balancerV3ERC4626AdaptorPoolHooksFacet_));
        // console.log("IndexedexFixture:balancerV3ERC4626AdaptorPoolHooksFacet():: Exiting function.");
        return balancerV3ERC4626AdaptorPoolHooksFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            ERC4626AwareFacet                           */
    /* ---------------------------------------------------------------------- */

    function erc4626AwareFacet(
        uint256 chainId,
        ERC4626AwareFacet erc4626AwareFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256,ERC4626AwareFacet):: Entering function.");
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256,ERC4626AwareFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256,ERC4626AwareFacet):: Storing instance mapped to initCodeHash: %s.", ERC4626_AWARE_FACET_INITCODE_HASH);
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256,ERC4626AwareFacet):: Instance to store: %s.", address(erc4626AwareFacet_));
        registerInstance(chainId, ERC4626_AWARE_FACET_INITCODE_HASH, address(erc4626AwareFacet_));
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256,ERC4626AwareFacet):: Declaring instance.");
        declare(builderKey_Crane(), "erc4626AwareFacet", address(erc4626AwareFacet_));
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256,ERC4626AwareFacet):: Exiting function.");
        return true;
    }

    function erc4626AwareFacet(ERC4626AwareFacet erc4626AwareFacet_) public returns (bool) {
        // console.log("IndexedexFixture:erc4626AwareFacet(ERC4626AwareFacet):: Entering function.");
        // console.log("IndexedexFixture:erc4626AwareFacet(ERC4626AwareFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:erc4626AwareFacet(ERC4626AwareFacet):: Instance to store: %s.", address(erc4626AwareFacet_));
        erc4626AwareFacet(block.chainid, erc4626AwareFacet_);
        // console.log("IndexedexFixture:erc4626AwareFacet(ERC4626AwareFacet):: Exiting function.");
        return true;
    }

    function erc4626AwareFacet(uint256 chainId) public view returns (ERC4626AwareFacet erc4626AwareFacet_) {
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:erc4626AwareFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", ERC4626_AWARE_FACET_INITCODE_HASH);
        erc4626AwareFacet_ = ERC4626AwareFacet(chainInstance(chainId, ERC4626_AWARE_FACET_INITCODE_HASH));
    }

    function erc4626AwareFacet() public returns (ERC4626AwareFacet erc4626AwareFacet_) {
        // console.log("IndexedexFixture:erc4626AwareFacet():: Entering function.");
        // console.log("IndexedexFixture:erc4626AwareFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(erc4626AwareFacet(block.chainid)) == address(0)) {
            // console.log("ERC4626AwareFacet not set on this chain, setting");
            // console.log("IndexedexFixture:erc4626AwareFacet():: Creating instance.");
            erc4626AwareFacet_ = ERC4626AwareFacet(
                factory().create3(
                    ERC4626_AWARE_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(ERC4626AwareFacet).name))
                )
            );
            // console.log("IndexedexFixture:erc4626AwareFacet():: Instance created: %s.", address(erc4626AwareFacet_));
            // console.log("IndexedexFixture:erc4626AwareFacet():: Storing instance.");
            erc4626AwareFacet(block.chainid, erc4626AwareFacet_);
        }
        // console.log("IndexedexFixture:erc4626AwareFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        erc4626AwareFacet_ = erc4626AwareFacet(block.chainid);
        // console.log("IndexedexFixture:erc4626AwareFacet():: Instance retrieved: %s.", address(erc4626AwareFacet_));
        // console.log("IndexedexFixture:erc4626AwareFacet():: Exiting function.");
        return erc4626AwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            ERC5115ViewFacet                            */
    /* ---------------------------------------------------------------------- */

    function erc5115ViewFacet(
        uint256 chainId,
        ERC5115ViewFacet erc5115ViewFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256,ERC5115ViewFacet):: Entering function.");
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256,ERC5115ViewFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256,ERC5115ViewFacet):: Storing instance mapped to initCodeHash: %s.", ERC5115_VIEW_FACET_INITCODE_HASH);
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256,ERC5115ViewFacet):: Instance to store: %s.", address(erc5115ViewFacet_));
        registerInstance(chainId, ERC5115_VIEW_FACET_INITCODE_HASH, address(erc5115ViewFacet_));
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256,ERC5115ViewFacet):: Declaring instance.");
        declare(builderKey_Crane(), "erc5115ViewFacet", address(erc5115ViewFacet_));
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256,ERC5115ViewFacet):: Exiting function.");
        return true;
    }

    function erc5115ViewFacet(ERC5115ViewFacet erc5115ViewFacet_) public returns (bool) {
        // console.log("IndexedexFixture:erc5115ViewFacet(ERC5115ViewFacet):: Entering function.");
        // console.log("IndexedexFixture:erc5115ViewFacet(ERC5115ViewFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:erc5115ViewFacet(ERC5115ViewFacet):: Instance to store: %s.", address(erc5115ViewFacet_));
        erc5115ViewFacet(block.chainid, erc5115ViewFacet_);
        // console.log("IndexedexFixture:erc5115ViewFacet(ERC5115ViewFacet):: Exiting function.");
        return true;
    }

    function erc5115ViewFacet(uint256 chainId) public view returns (ERC5115ViewFacet erc5115ViewFacet_) {
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", ERC5115_VIEW_FACET_INITCODE_HASH);
        erc5115ViewFacet_ = ERC5115ViewFacet(chainInstance(chainId, ERC5115_VIEW_FACET_INITCODE_HASH));
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256):: Instance retrieved: %s.", address(erc5115ViewFacet_));
        // console.log("IndexedexFixture:erc5115ViewFacet(uint256):: Exiting function.");
        return erc5115ViewFacet_;
    }

    function erc5115ViewFacet() public returns (ERC5115ViewFacet erc5115ViewFacet_) {
        // console.log("IndexedexFixture:erc5115ViewFacet():: Entering function.");
        // console.log("IndexedexFixture:erc5115ViewFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(erc5115ViewFacet(block.chainid)) == address(0)) {
            // console.log("ERC5115ViewFacet not set on this chain, setting");
            // console.log("IndexedexFixture:erc5115ViewFacet():: Creating instance.");
            erc5115ViewFacet_ = ERC5115ViewFacet(
                factory().create3(
                    ERC5115_VIEW_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(ERC5115ViewFacet).name))
                )
            );
            // console.log("IndexedexFixture:erc5115ViewFacet():: Instance created: %s.", address(erc5115ViewFacet_));
            // console.log("IndexedexFixture:erc5115ViewFacet():: Storing instance.");
            erc5115ViewFacet(block.chainid, erc5115ViewFacet_);
        }
        // console.log("IndexedexFixture:erc5115ViewFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        erc5115ViewFacet_ = erc5115ViewFacet(block.chainid);
        // console.log("IndexedexFixture:erc5115ViewFacet():: Instance retrieved: %s.", address(erc5115ViewFacet_));
        // console.log("IndexedexFixture:erc5115ViewFacet():: Exiting function.");
        return erc5115ViewFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        ERC5115ExtensionViewFacet                       */
    /* ---------------------------------------------------------------------- */

    function erc5115ExtensionViewFacet(
        uint256 chainId,
        ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256,ERC5115ExtensionViewFacet):: Entering function.");
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256,ERC5115ExtensionViewFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256,ERC5115ExtensionViewFacet):: Storing instance mapped to initCodeHash: %s.", ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH);
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256,ERC5115ExtensionViewFacet):: Instance to store: %s.", address(erc5115ExtensionViewFacet_));
        registerInstance(chainId, ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH, address(erc5115ExtensionViewFacet_));
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256,ERC5115ExtensionViewFacet):: Declaring instance.");
        declare(builderKey_Crane(), "erc5115ExtensionViewFacet", address(erc5115ExtensionViewFacet_));
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256,ERC5115ExtensionViewFacet):: Exiting function.");
        return true;
    }

    function erc5115ExtensionViewFacet(ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_) public returns (bool) {
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(ERC5115ExtensionViewFacet):: Entering function.");
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(ERC5115ExtensionViewFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(ERC5115ExtensionViewFacet):: Instance to store: %s.", address(erc5115ExtensionViewFacet_));
        erc5115ExtensionViewFacet(block.chainid, erc5115ExtensionViewFacet_);
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(ERC5115ExtensionViewFacet):: Exiting function.");
        return true;
    }

    function erc5115ExtensionViewFacet(uint256 chainId) public view returns (ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_) {
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH);
        erc5115ExtensionViewFacet_ = ERC5115ExtensionViewFacet(chainInstance(chainId, ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH));
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256):: Instance retrieved: %s.", address(erc5115ExtensionViewFacet_));
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet(uint256):: Exiting function.");
        return erc5115ExtensionViewFacet_;
    }

    function erc5115ExtensionViewFacet() public returns (ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_) {
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Entering function.");
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(erc5115ExtensionViewFacet(block.chainid)) == address(0)) {
            // console.log("ERC5115ExtensionViewFacet not set on this chain, setting");
            // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Creating instance.");
            erc5115ExtensionViewFacet_ = ERC5115ExtensionViewFacet(
                factory().create3(
                    ERC5115_EXTENSION_VIEW_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(ERC5115ExtensionViewFacet).name))
                )
            );
            // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Instance created: %s.", address(erc5115ExtensionViewFacet_));
            // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Storing instance.");
            erc5115ExtensionViewFacet(block.chainid, erc5115ExtensionViewFacet_);
        }
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        erc5115ExtensionViewFacet_ = erc5115ExtensionViewFacet(block.chainid);
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Instance retrieved: %s.", address(erc5115ExtensionViewFacet_));
        // console.log("IndexedexFixture:erc5115ExtensionViewFacet():: Exiting function.");
        return erc5115ExtensionViewFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        PowerCalculatorAwareFacet                       */
    /* ---------------------------------------------------------------------- */

    function powerCalculatorAwareFacet(
        uint256 chainId,
        PowerCalculatorAwareFacet powerCalculatorAwareFacet_
    ) public returns (bool) {
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256,PowerCalculatorAwareFacet):: Entering function.");
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256,PowerCalculatorAwareFacet):: Storing instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256,PowerCalculatorAwareFacet):: Storing instance mapped to initCodeHash: %s.", POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH);
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256,PowerCalculatorAwareFacet):: Instance to store: %s.", address(powerCalculatorAwareFacet_));
        registerInstance(chainId, POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH, address(powerCalculatorAwareFacet_));
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256,PowerCalculatorAwareFacet):: Declaring instance.");
        declare(builderKey_Crane(), "powerCalculatorAwareFacet", address(powerCalculatorAwareFacet_));
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256,PowerCalculatorAwareFacet):: Exiting function.");
        return true;
    }

    function powerCalculatorAwareFacet(PowerCalculatorAwareFacet powerCalculatorAwareFacet_) public returns (bool) {
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(PowerCalculatorAwareFacet):: Entering function.");
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(PowerCalculatorAwareFacet):: Storing instance mapped to chainId %s.", block.chainid);
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(PowerCalculatorAwareFacet):: Instance to store: %s.", address(powerCalculatorAwareFacet_));
        powerCalculatorAwareFacet(block.chainid, powerCalculatorAwareFacet_);
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(PowerCalculatorAwareFacet):: Exiting function.");
        return true;
    }

    function powerCalculatorAwareFacet(uint256 chainId) public view returns (PowerCalculatorAwareFacet powerCalculatorAwareFacet_) {
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256):: Entering function.");
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256):: Retrieving instance mapped to chainId %s.", chainId);
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256):: Retrieving instance mapped to initCodeHash: %s.", POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH);
        powerCalculatorAwareFacet_ = PowerCalculatorAwareFacet(chainInstance(chainId, POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH));
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256):: Instance retrieved: %s.", address(powerCalculatorAwareFacet_));
        // console.log("IndexedexFixture:powerCalculatorAwareFacet(uint256):: Exiting function.");
        return powerCalculatorAwareFacet_;
    }

    function powerCalculatorAwareFacet() public returns (PowerCalculatorAwareFacet powerCalculatorAwareFacet_) {
        // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Entering function.");
        // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Checking if instance has been declared for chainid: %s.", block.chainid);
        if(address(powerCalculatorAwareFacet(block.chainid)) == address(0)) {
            // console.log("PowerCalculatorAwareFacet not set on this chain, setting");
            // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Creating instance.");
            powerCalculatorAwareFacet_ = PowerCalculatorAwareFacet(
                factory().create3(
                    POWER_CALCULATOR_AWARE_FACET_INITCODE,
                    "",
                    keccak256(abi.encode(type(PowerCalculatorAwareFacet).name))
                )
            );
            // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Instance created: %s.", address(powerCalculatorAwareFacet_));
            // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Storing instance.");
            powerCalculatorAwareFacet(block.chainid, powerCalculatorAwareFacet_);
        }
        // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Retrieving instance mapped to chainId %s.", block.chainid);
        powerCalculatorAwareFacet_ = powerCalculatorAwareFacet(block.chainid);
        // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Instance retrieved: %s.", address(powerCalculatorAwareFacet_));
        // console.log("IndexedexFixture:powerCalculatorAwareFacet():: Exiting function.");
        return powerCalculatorAwareFacet_;
    }


}