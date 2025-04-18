// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;


import {LOCAL} from "../networks/LOCAL.sol";

import {ETHEREUM_MAIN} from "../networks/ethereum/ETHEREUM_MAIN.sol";

import {ETHEREUM_SEPOLIA} from "../networks/ethereum/ETHEREUM_SEPOLIA.sol";

import {APE_CHAIN_MAIN} from "../networks/arbitrum/apechain/constants/APE_CHAIN_MAIN.sol";

import {APE_CHAIN_CURTIS} from "../networks/arbitrum/apechain/constants/APE_CHAIN_CURTIS.sol";

import "../constants/CraneINITCODE.sol";

import {FoundryVM} from "../utils/vm/foundry/FoundryVM.sol";

// import "contracts/crane/utils/Primitives.sol";
import {
    Fixture
} from "./Fixture.sol";

import {
    Creation
} from "../utils/Creation.sol";

import {
    CamelotV2Fixture
} from "../protocols/dexes/camelot/v2/fixtures/CamelotV2Fixture.sol";

import {
    ICreate2CallbackFactory
} from "../factories/create2/callback/interfaces/ICreate2CallbackFactory.sol";

import {
    Create2CallBackFactoryTarget
} from "../factories/create2/callback/targets/Create2CallBackFactoryTarget.sol";

import {
    IDiamondPackageCallBackFactory
} from "../factories/create2/callback/diamondPkg/interfaces/IDiamondPackageCallBackFactory.sol";

import {
    IPower
} from "../utils/math/power-calc/interfaces/IPower.sol";

import {
    PowerCalculatorC2ATarget
} from "../utils/math/power-calc/targets/PowerCalculatorC2ATarget.sol";

import {
    IDiamondCutFacetDFPkg,
    DiamondCutFacetDFPkg
} from "../introspection/erc2535/dfPkgs/DiamondCutFacetDFPkg.sol";

import {
    IERC20Permit
} from "../tokens/erc20/interfaces/IERC20Permit.sol";

import {
    IERC20PermitDFPkg,
    ERC20PermitDFPkg
} from "../tokens/erc20/dfPkgs/ERC20PermitDFPkg.sol";

/**
 * @title CraneFixture
 * @author cyotee doge <doge.cyotee>
 * @notice A singleton factory for Crane contracts.
 */
contract CraneFixture
is
FoundryVM,
Fixture,
CamelotV2Fixture
{

    using Creation for bytes;


    function builderKey_Crane() public pure returns (string memory) {
        return "crane";
    }

    function initialize() public virtual 
    override(
        Fixture,
        CamelotV2Fixture
    ) {
        // Fixture.initialize();
        // CamelotV2Fixture.initialize();
        // _log("CraneFixture:setUp():: Entering function.");
        // _log("Declaring addresses of Crane in json of all.");
        // _log("Declaring factory.");
        declare(vm.getLabel(address(factory())), address(factory()));
        // _log("Factory declared.");
        // _log("Declaring diamond factory.");
        declare(vm.getLabel(address(diamondFactory())), address(diamondFactory()));
        // _log("Diamond factory declared.");
        // _log("Declaring power calculator.");
        declare(vm.getLabel(address(powerCalculator())), address(powerCalculator()));
        // _log("Power calculator declared.");
        // _log("Declaring ownable facet.");
        declare(vm.getLabel(address(ownableFacet())), address(ownableFacet()));
        // _log("Ownable facet declared.");
        // _log("Declaring operable facet.");
        declare(vm.getLabel(address(operableFacet())), address(operableFacet()));
        // _log("Operable facet declared.");
        // _log("Declaring reentrancy lock facet.");
        declare(vm.getLabel(address(reentrancyLockFacet())), address(reentrancyLockFacet()));
        // _log("Reentrancy lock facet declared.");
        // _log("Declaring ERC20 permit facet.");
        declare(vm.getLabel(address(erc20PermitFacet())), address(erc20PermitFacet()));
        // _log("ERC20 permit facet declared.");
        // _log("Declaring ERC20 permit package.");
        declare(vm.getLabel(address(erc20PermitDFPkg())), address(erc20PermitDFPkg()));
        // _log("ERC20 permit package declared.");
        // _log("Declaring ERC20 mint burn operable facet diamond factory package.");
        declare(vm.getLabel(address(erc20MintBurnPkg())), address(erc20MintBurnPkg()));
        // _log("ERC20 mint burn operable facet diamond factory package declared.");
        // _log("CraneFixture:setUp():: Exiting function.");
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Crane                                 */
    /* ---------------------------------------------------------------------- */

    /* -------------------------------- Tools ------------------------------- */

    // Create2CallBackFactoryTarget internal _factory;

    function factory(
        uint256 chainid,
        Create2CallBackFactoryTarget factory_
    ) public returns(bool) {
        // _log("CraneFixture:factory():: Entering function.");
        // _log("Setting provided factory of %s", address(factory_));
        // _factory = factory_;
        registerInstance(chainid, CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE_HASH, address(factory_));
        // _log("Declaring address of Create2CallBackFactoryTarget.");
        declare(builderKey_Crane(), "factory", address(factory_));
        // _log("Declared address of Create2CallBackFactoryTarget.");
        return true;
    }

    /**
     * @notice Declares the factory for later use.
     * @param factory_ The factory to declare.
     * @return true if the factory was declared.
     */
    function factory(Create2CallBackFactoryTarget factory_) public returns(bool) {
        // _log("CraneFixture:factory():: Entering function.");
        // _log("Setting provided factory of %s", address(factory_));
        // _factory = factory_;
        factory(block.chainid, factory_);
        // _log("Declaring address of Create2CallBackFactoryTarget.");
        declare(builderKey_Crane(), "factory", address(factory_));
        // _log("Declared address of Create2CallBackFactoryTarget.");
        return true;
    }

    function factory(uint256 chainid)
    public virtual view returns(Create2CallBackFactoryTarget factory_) {
        factory_ = Create2CallBackFactoryTarget(chainInstance(chainid, CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE_HASH));
    }

    /**
     * @dev CREATE2 factory is owned by msg.sender.
     * @dev This will the broadcast wallet when executing a script.
     * @dev This will be the inheriting test when testing, you prank on first call.
     * @return factory_ The CREATE2 factory.
     */
    function factory()
    public virtual returns(Create2CallBackFactoryTarget factory_) {
        // _log("CraneFixture:factory():: Entering function.");
        // _log("Checking if Create2CallBackFactoryTarget is declared.");
        if(address(factory(block.chainid)) == address(0)) {
            // _log("Create2CallBackFactoryTarget is not declared, deploying...");
            // factory_ = new Create2CallBackFactoryTarget();
            factory_ = Create2CallBackFactoryTarget(CREATE2_CALLBACK_FACTORY_TARGET_INIT_CODE._create());
            // _log("Create2CallBackFactoryTarget deployed @ ", address(factory_));
            // _log("Setting factory for later use.");
            factory(factory_);
            // _log("Factory set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:factory():: Exiting function.");
        // return _factory;
        return factory(block.chainid);
    }

    // IDiamondPackageCallBackFactory _diamondFactory;

    function diamondFactory(
        uint256 chainid,
        IDiamondPackageCallBackFactory diamondFactory_
    ) public returns(bool) {
        registerInstance(chainid, DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH, address(diamondFactory_));
        declare(builderKey_Crane(), "diamondFactory", address(diamondFactory_));
        return true;
    }

    /**
     * @notice Declares the diamond factory for later use.
     * @param diamondFactory_ The diamond factory to declare.
     * @return true if the diamond factory was declared.
     */
    function diamondFactory(IDiamondPackageCallBackFactory diamondFactory_) public returns(bool) {
        // _log("CraneFixture:diamondFactory():: Entering function.");
        // _log("Setting provided diamond factory of %s", address(diamondFactory_));
        diamondFactory(block.chainid, diamondFactory_);
        // _log("Declaring address of IDiamondPackageCallBackFactory.");
        declare(builderKey_Crane(), "diamondFactory", address(diamondFactory_));
        // _log("Declared address of IDiamondPackageCallBackFactory.");
        return true;
    }

    function diamondFactory(uint256 chainid)
    public virtual view returns(IDiamondPackageCallBackFactory diamondFactory_) {
        diamondFactory_ = IDiamondPackageCallBackFactory(chainInstance(chainid, DIAMOND_PACKAGE_FACTORY_INIT_CODE_HASH));
    }

    /**
     * @notice A package based factory for deploying diamond proxies.
     * @return diamondFactory_ The diamond factory.
     */
    function diamondFactory() public virtual returns (IDiamondPackageCallBackFactory diamondFactory_) {
        // _log("CraneFixture:diamondFactory():: Entering function.");
        // _log("Checking if IDiamondPackageCallBackFactory is declared.");
        if (address(diamondFactory(block.chainid)) == address(0)) {
            // _log("IDiamondPackageCallBackFactory is not declared, deploying...");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                diamondFactory_ = IDiamondPackageCallBackFactory(APE_CHAIN_MAIN.CRANE_DIAMOND_FACTORY_V1);
                // diamondFactory(diamondFactory_);
            } else {
                diamondFactory_ = DiamondPackageCallBackFactory(
                    factory().create2(
                        DIAMOND_PACKAGE_FACTORY_INIT_CODE,
                        ""
                    )
                );
            }
            // _log("IDiamondPackageCallBackFactory deployed @ ", address(diamondFactory_));
            // _log("Setting diamond factory for later use.");
            diamondFactory(diamondFactory_);
            // _log("Diamond factory set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:diamondFactory():: Exiting function.");
        return diamondFactory(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Facets                                 */
    /* ---------------------------------------------------------------------- */

    // PowerCalculatorC2ATarget internal _powerCalculator;

    function powerCalculator(
        uint256 chainid,
        PowerCalculatorC2ATarget powerCalculator_
    ) public returns(bool) {
        registerInstance(chainid, POWER_CALC_INIT_CODE_HASH, address(powerCalculator_));
        declare(builderKey_Crane(), "powerCalculator", address(powerCalculator_));
        return true;
    }

    /** 
     * @notice Declares the power calculator for later use.
     * @param powerCalculator_ The power calculator to declare.
     * @return true if the power calculator was declared.
     */
    function powerCalculator(PowerCalculatorC2ATarget powerCalculator_) public returns(bool) {
        // _log("CraneFixture:powerCalculator():: Entering function.");
        // _log("Setting provided power calculator of %s", address(powerCalculator_));
        powerCalculator(block.chainid, powerCalculator_);
        // _log("Declaring address of PowerCalculatorC2ATarget.");
        declare(builderKey_Crane(), "powerCalculator", address(powerCalculator_));
        // _log("Declared address of PowerCalculatorC2ATarget.");
        return true;
    }

    function powerCalculator(uint256 chainid)
    public virtual view returns(PowerCalculatorC2ATarget powerCalculator_) {
        powerCalculator_ = PowerCalculatorC2ATarget(chainInstance(chainid, POWER_CALC_INIT_CODE_HASH));
    }

    /**
     * @notice Power calculator.
     * @notice Does gas efficient power calculations.
     * @notice Externalized to save bytecode size.
     * @return powerCalculator_ The power calculator.    
     */
    function powerCalculator()
    public virtual returns(PowerCalculatorC2ATarget powerCalculator_) {
        // _log("CraneFixture:powerCalculator():: Entering function.");
        // _log("Checking if PowerCalculatorC2ATarget is declared.");
        if(address(powerCalculator(block.chainid)) == address(0)) {
            // _log("PowerCalculatorC2ATarget is not declared, deploying...");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                powerCalculator_ = PowerCalculatorC2ATarget(APE_CHAIN_MAIN.CRANE_POWER_CALCULATOR_V1);
            } else {
                powerCalculator_ = PowerCalculatorC2ATarget(
                    factory().create2(
                        POWER_CALC_INIT_CODE,
                        ""
                    )
                );
            }
            // _log("PowerCalculatorC2ATarget deployed @ ", address(powerCalculator_));
            // _log("Setting power calculator for later use.");
            powerCalculator(powerCalculator_);
            // _log("Power calculator set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:powerCalculator():: Exiting function.");
        return powerCalculator(block.chainid);
    }

    // OwnableFacet internal _ownableFacet;

    function ownableFacet(
        uint256 chainid,
        OwnableFacet ownableFacet_
    ) public returns(bool) {
        registerInstance(chainid, OWNABLE_FACET_INIT_CODE_HASH, address(ownableFacet_));
        declare(builderKey_Crane(), "ownableFacet", address(ownableFacet_));
        return true;
    }

    /**
     * @notice Declares the ownable facet for later use.
     * @param ownableFacet_ The ownable facet to declare.
     * @return true if the ownable facet was declared.
     */
    function ownableFacet(OwnableFacet ownableFacet_) public returns(bool) {
        // _log("CraneFixture:ownableFacet():: Entering function.");   
        // _log("Setting provided ownable facet of %s", address(ownableFacet_));
        ownableFacet(block.chainid, ownableFacet_);
        // _log("Declaring address of OwnableFacet.");
        declare(builderKey_Crane(), "ownableFacet", address(ownableFacet_));
        // _log("Declared address of OwnableFacet.");
        return true;
    }

    function ownableFacet(uint256 chainid)
    public virtual view returns(OwnableFacet ownableFacet_) {
        ownableFacet_ = OwnableFacet(chainInstance(chainid, OWNABLE_FACET_INIT_CODE_HASH));
    }

    /**
     * @notice Ownable facet.
     * @notice Exposes IOwnable so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply ownable modifiers.
     * @return ownableFacet_ The ownable facet.
     */
    function ownableFacet() public returns (OwnableFacet ownableFacet_) {
        // _log("CraneFixture:ownableFacet():: Entering function.");
        // _log("Checking if OwnableFacet is declared.");
        if (address(ownableFacet(block.chainid)) == address(0)) {
            // _log("OwnableFacet is not declared, deploying...");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                ownableFacet_ = OwnableFacet(APE_CHAIN_MAIN.CRANE_OWNABLE_FACET_V1);
            } else {
                ownableFacet_ = OwnableFacet(
                    factory().create2(
                        OWNABLE_FACET_INIT_CODE,
                        ""
                    )
                );
            }
            // _log("OwnableFacet deployed @ ", address(ownableFacet_));
            // _log("Setting ownable facet for later use.");
            ownableFacet(ownableFacet_);
            // _log("Ownable facet set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:ownableFacet():: Exiting function.");
        return ownableFacet(block.chainid);
    }

    // OperableFacet internal _operableFacet;

    function operableFacet(
        uint256 chainid,
        OperableFacet operableFacet_
    ) public returns(bool) {
        registerInstance(chainid, OPERABLE_FACET_INIT_CODE_HASH, address(operableFacet_));
        declare(builderKey_Crane(), "operableFacet", address(operableFacet_));
        return true;
    }

    /** 
     * @notice Declares the operable facet for later use.
     * @param operableFacet_ The operable facet to declare.
     * @return true if the operable facet was declared.
     */
    function operableFacet(OperableFacet operableFacet_) public returns(bool) {
        // _log("CraneFixture:operableFacet():: Entering function.");
        // _log("Setting provided operable facet of %s", address(operableFacet_));
        operableFacet(block.chainid, operableFacet_);
        // _log("Declaring address of OperableFacet.");
        declare(builderKey_Crane(), "operableFacet", address(operableFacet_));
        // _log("Declared address of OperableFacet.");
        return true;
    }

    function operableFacet(uint256 chainid)
    public virtual view returns(OperableFacet operableFacet_) {
        operableFacet_ = OperableFacet(chainInstance(chainid, OPERABLE_FACET_INIT_CODE_HASH));
    }

    /**
     * @notice Operable facet.
     * @notice Exposes IOperable so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply operable modifiers.
     * @return operableFacet_ The operable facet.
     */
    function operableFacet() public returns (OperableFacet operableFacet_) {
        // _log("CraneFixture:operableFacet():: Entering function.");
        // _log("Checking if OperableFacet is declared.");
        if (address(operableFacet(block.chainid)) == address(0)) {    
            // _log("OperableFacet is not declared, deploying...");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                operableFacet_ = OperableFacet(APE_CHAIN_MAIN.CRANE_OPERABLE_FACET_V1);
            } else {
                operableFacet_ = OperableFacet(
                        factory().create2(
                        OPERABLE_FACET_INIT_CODE,
                        ""
                    )
                );
            }
            // _log("OperableFacet deployed @ ", address(operableFacet_));
            // _log("Setting operable facet for later use.");
            operableFacet(operableFacet_);
            // _log("Operable facet set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:operableFacet():: Exiting function.");
        return operableFacet(block.chainid);
    }

    // ReentrancyLockFacet internal _reentrancyLockFacet;

    function reentrancyLockFacet(
        uint256 chainid,
        ReentrancyLockFacet reentrancyLockFacet_
    ) public returns(bool) {
        registerInstance(chainid, REENTRANCY_LOCK_FACET_INIT_CODE_HASH, address(reentrancyLockFacet_));
        declare(builderKey_Crane(), "reentrancyLockFacet", address(reentrancyLockFacet_));
        return true;
    }

    /** 
     * @notice Declares the reentrancy lock facet for later use.
     * @param reentrancyLockFacet_ The reentrancy lock facet to declare.
     * @return true if the reentrancy lock facet was declared.
     */
    function reentrancyLockFacet(ReentrancyLockFacet reentrancyLockFacet_) public returns(bool) {
        // _log("CraneFixture:reentrancyLockFacet():: Entering function.");
        // _log("Setting provided reentrancy lock facet of %s", address(reentrancyLockFacet_));
        reentrancyLockFacet(block.chainid, reentrancyLockFacet_);
        // _log("Declaring address of ReentrancyLockFacet.");
        // declare(builderKey_Crane(), "reentrancyLockFacet", address(reentrancyLockFacet_));
        // _log("Declared address of ReentrancyLockFacet.");
        return true;
    }   

    function reentrancyLockFacet(uint256 chainid)
    public virtual view returns(ReentrancyLockFacet reentrancyLockFacet_) {
        reentrancyLockFacet_ = ReentrancyLockFacet(chainInstance(chainid, REENTRANCY_LOCK_FACET_INIT_CODE_HASH));
    }

    /**
     * @notice Reentrancy lock facet.
     * @notice Exposes IReentrancyLock so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply reentrancy lock modifiers.
     * @return reentrancyLockFacet_ The reentrancy lock facet.
     */
    function reentrancyLockFacet() public returns (ReentrancyLockFacet reentrancyLockFacet_) {
        // _log("CraneFixture:reentrancyLockFacet():: Entering function.");
        // _log("Checking if ReentrancyLockFacet is declared.");
        if (address(reentrancyLockFacet(block.chainid)) == address(0)) {
            // _log("ReentrancyLockFacet is not declared, deploying...");
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                reentrancyLockFacet_ = ReentrancyLockFacet(APE_CHAIN_MAIN.CRANE_REENTRANCY_LOCK_FACET_V1);
            } else {
                reentrancyLockFacet_ = ReentrancyLockFacet(
                    factory().create2(
                        REENTRANCY_LOCK_FACET_INIT_CODE,
                        ""
                    )
                );
            }
            // _log("ReentrancyLockFacet deployed @ ", address(reentrancyLockFacet_));
            // _log("Setting reentrancy lock facet for later use.");
            reentrancyLockFacet(reentrancyLockFacet_);
            // _log("Reentrancy lock facet set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:reentrancyLockFacet():: Exiting function.");
        return reentrancyLockFacet(block.chainid);
    }

    ERC20PermitFacet internal _erc20PermitFacet;

    /**
     * @notice Declares the ERC20 permit facet for later use.
     * @param erc20PermitFacet_ The ERC20 permit facet to declare.
     * @return true if the ERC20 permit facet was declared.
     */
    function erc20PermitFacet(ERC20PermitFacet erc20PermitFacet_) public returns(bool) {
        // _log("CraneFixture:erc20PermitFacet():: Entering function.");
        // _log("Setting provided ERC20 permit facet of %s", address(erc20PermitFacet_));
        _erc20PermitFacet = erc20PermitFacet_;
        // _log("Declaring address of ERC20PermitFacet.");
        declare(builderKey_Crane(), "erc20PermitFacet", address(erc20PermitFacet_));
        // _log("Declared address of ERC20PermitFacet.");
        return true;
    }

    /**
     * @notice ERC20 permit facet.
     * @notice Exposes ERC20Permit so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply ERC20 permit modifiers.
     * @return erc20PermitFacet_ The ERC20 permit facet.
     */
    function erc20PermitFacet() public returns (ERC20PermitFacet erc20PermitFacet_) {
        // _log("CraneFixture:erc20PermitFacet():: Entering function.");
        // _log("Checking if ERC20PermitFacet is declared.");
        if (address(_erc20PermitFacet) == address(0)) {
            // _log("ERC20PermitFacet is not declared, deploying...");
            erc20PermitFacet_ = ERC20PermitFacet(
                factory().create2(ERC20_PERMIT_FACET_INIT_CODE, "")
            );
            // _log("ERC20PermitFacet deployed @ ", address(erc20PermitFacet_));
            // _log("Setting ERC20 permit facet for later use.");
            erc20PermitFacet(erc20PermitFacet_);
            // _log("ERC20 permit facet set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:erc20PermitFacet():: Exiting function.");
        return _erc20PermitFacet;
    }

    /* ---------------------------------------------------------------------- */
    /*                                Packages                                */
    /* ---------------------------------------------------------------------- */

    ERC20PermitDFPkg internal _erc20PermitDFPkg;

    /** 
     * @notice Declares the ERC20 permit package for later use.
     * @param erc20PermitDFPkg_ The ERC20 permit package to declare.
     * @return true if the ERC20 permit package was declared.
     */
    function erc20PermitDFPkg(ERC20PermitDFPkg erc20PermitDFPkg_) public returns(bool) {
        // _log("CraneFixture:erc20PermitDFPkg():: Entering function.");
        // _log("Setting provided ERC20 permit package of %s", address(erc20PermitDFPkg_));
        _erc20PermitDFPkg = erc20PermitDFPkg_;
        // _log("Declaring address of ERC20PermitDFPkg.");
        declare(builderKey_Crane(), "erc20PermitDFPkg", address(erc20PermitDFPkg_));
        // _log("Declared address of ERC20PermitDFPkg.");
        return true;
    }

    /**
     * @notice ERC20 permit package.
     * @notice Deploys a DiamondFactorPackage for deploying ERC20PermitFacet proxies.
     * @return erc20PermitDFPkg_ The ERC20 permit package.
     */
    function erc20PermitDFPkg() public returns (ERC20PermitDFPkg erc20PermitDFPkg_) {
        // _log("CraneFixture:erc20PermitDFPkg():: Entering function.");
        // _log("Checking if ERC20PermitDFPkg is declared.");
        if (address(_erc20PermitDFPkg) == address(0)) {
            // _log("ERC20PermitDFPkg is not declared, deploying...");
            // _log("Setting Package initialization arguments.");
            IERC20PermitDFPkg.ERC20PermitDFPkgInit memory erc20PermitDFPkgInit;
            // _log("Setting erc20PermitFacet to ", address(erc20PermitFacet()));
            erc20PermitDFPkgInit.erc20PermitFacet = erc20PermitFacet();

            // _log("Deploying ERC20PermitDFPkg.");
            erc20PermitDFPkg_ = ERC20PermitDFPkg(
                factory().create2(
                    ERC20_PERMIT_FACET_DFPKG_INIT_CODE,
                    abi.encode(erc20PermitDFPkgInit)
                )
            );
            // _log("ERC20PermitDFPkg deployed @ ", address(erc20PermitDFPkg_));
            // _log("Setting ERC20 permit package for later use.");
            erc20PermitDFPkg(erc20PermitDFPkg_);
            // _log("ERC20 permit package set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:erc20PermitDFPkg():: Exiting function.");
        return _erc20PermitDFPkg;
    }

    ERC20MintBurnOperableFacetDFPkg internal _erc20MintBurnPkg;

    /**
     * @notice Declares the ERC20 mint burn operable facet diamond factory package for later use.
     * @param erc20MintBurnPkg_ The ERC20 mint burn operable facet diamond factory package to declare.
     * @return true if the ERC20 mint burn operable facet diamond factory package was declared.
     */
    function erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) public returns(bool) {
        // _log("CraneFixture:erc20MintBurnPkg():: Entering function.");   
        // _log("Setting provided ERC20 mint burn operable facet diamond factory package of %s", address(erc20MintBurnPkg_));
        _erc20MintBurnPkg = erc20MintBurnPkg_;
        // _log("Declaring address of ERC20MintBurnOperableFacetDFPkg.");
        declare(builderKey_Crane(), "erc20MintBurnPkg", address(erc20MintBurnPkg_));
        // _log("Declared address of ERC20MintBurnOperableFacetDFPkg.");
        return true;
    }   

    /**
     * @notice ERC20 mint burn operable facet diamond factory package.
     * @notice Deploys a DiamondFactorPackage for deploying ERC20MintBurnOperableFacet proxies.
     * @return erc20MintBurnPkg_ The ERC20 mint burn operable facet diamond factor package.
     */
    function erc20MintBurnPkg() public returns (ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) {
        // _log("CraneFixture:erc20MintBurnPkg():: Entering function.");
        // _log("Checking if ERC20MintBurnOperableFacetDFPkg is declared.");
        if (address(_erc20MintBurnPkg) == address(0)) {
            // _log("ERC20MintBurnOperableFacetDFPkg is not declared, deploying...");
            // _log("Setting Package initialization arguments.");
            ERC20MintBurnOperableFacetDFPkg
                .PkgInit memory erc20MintPkgInit;
            // _log("Setting ownableFacet to ", address(ownableFacet()));
            erc20MintPkgInit.ownableFacet = ownableFacet();
            // _log("Setting operableFacet to ", address(operableFacet()));
            erc20MintPkgInit.operableFacet = operableFacet();
            // _log("Setting erc20PermitFacet to ", address(erc20PermitFacet()));
            erc20MintPkgInit.erc20PermitFacet = erc20PermitFacet();

            // _log("Deploying ERC20MintBurnOperableFacetDFPkg.");
            erc20MintBurnPkg_ = ERC20MintBurnOperableFacetDFPkg(
                factory().create2(
                    ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE,
                    abi.encode(erc20MintPkgInit)
                )
            );
            // _log("ERC20MintBurnOperableFacetDFPkg deployed @ ", address(erc20MintBurnPkg_));
            // _log("Setting ERC20 mint burn operable facet diamond factory package for later use.");
            erc20MintBurnPkg(erc20MintBurnPkg_);
            // _log("ERC20 mint burn operable facet diamond factory package set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:erc20MintBurnPkg():: Exiting function.");
        return _erc20MintBurnPkg;
    }

    DiamondCutFacetDFPkg internal _diamondCutFacetDFPkg;

    function diamondCutFacetDFPkg(DiamondCutFacetDFPkg diamondCutFacetDFPkg_) public returns(bool) {
        // _log("CraneFixture:diamondCutFacetDFPkg():: Entering function.");
        // _log("Setting provided diamond cut facet diamond factory package of %s", address(diamondCutFacetDFPkg_));
        _diamondCutFacetDFPkg = diamondCutFacetDFPkg_;
        // _log("Declaring address of DiamondCutFacetDFPkg.");
        declare(builderKey_Crane(), "diamondCutFacetDFPkg", address(diamondCutFacetDFPkg_));
        // _log("Declared address of DiamondCutFacetDFPkg.");
        return true;
    }

    function diamondCutFacetDFPkg() public returns (DiamondCutFacetDFPkg diamondCutFacetDFPkg_) {
        // _log("CraneFixture:diamondCutFacetDFPkg():: Entering function.");
        // _log("Checking if DiamondCutFacetDFPkg is declared.");
        if (address(_diamondCutFacetDFPkg) == address(0)) {
            // _log("DiamondCutFacetDFPkg is not declared, deploying...");
            // _log("Setting Package initialization arguments.");
            DiamondCutFacetDFPkg.DiamondCutPkgInit memory diamondCutPkgInit;
            // _log("Setting ownableFacet to ", address(ownableFacet()));
            diamondCutPkgInit.ownableFacet = ownableFacet();
            // _log("Deploying DiamondCutFacetDFPkg.");
            diamondCutFacetDFPkg_ = DiamondCutFacetDFPkg(
                factory().create2(
                    DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE,
                    abi.encode(diamondCutPkgInit)
                )
            );
            // _log("DiamondCutFacetDFPkg deployed @ ", address(diamondCutFacetDFPkg_));
            // _log("Setting diamond cut facet diamond factory package for later use.");
            diamondCutFacetDFPkg(diamondCutFacetDFPkg_);
            // _log("Diamond cut facet diamond factory package set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:diamondCutFacetDFPkg():: Exiting function.");
        return _diamondCutFacetDFPkg;
    }

    GreeterFacet internal _greeterFacet;

    function greeterFacet(GreeterFacet greeterFacet_) public returns(bool) {
        // _log("CraneFixture:greeterFacet():: Entering function.");
        // _log("Setting provided greeter facet of %s", address(greeterFacet_));
        _greeterFacet = greeterFacet_;
        // _log("Declaring address of GreeterFacet.");
        declare(builderKey_Crane(), "greeterFacet", address(greeterFacet_));
        // _log("Declared address of GreeterFacet.");
        return true;
    }

    function greeterFacet() public returns (GreeterFacet greeterFacet_) {
        // _log("CraneFixture:greeterFacet():: Entering function.");
        // _log("Checking if GreeterFacet is declared.");
        if (address(_greeterFacet) == address(0)) {
            // _log("GreeterFacet is not declared, deploying...");
            greeterFacet_ = GreeterFacet(
                factory().create2(
                    GREETER_FACET_INIT_CODE,
                    ""
                )
            );
            // _log("GreeterFacet deployed @ ", address(greeterFacet_));
            // _log("Setting greeter facet for later use.");
            greeterFacet(greeterFacet_);
            // _log("Greeter facet set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:greeterFacet():: Exiting function.");
        return _greeterFacet;
    }

    GreeterFacetDiamondFactoryPackage internal _greeterFacetDFPkg;

    function greeterFacetDFPkg(GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) public returns(bool) {
        // _log("CraneFixture:greeterFacetDFPkg():: Entering function.");
        // _log("Setting provided greeter facet diamond factory package of %s", address(greeterFacetDFPkg_));
        _greeterFacetDFPkg = greeterFacetDFPkg_;
        // _log("Declaring address of GreeterFacetDiamondFactoryPackage.");
        declare(builderKey_Crane(), "greeterFacetDFPkg", address(greeterFacetDFPkg_));
        // _log("Declared address of GreeterFacetDiamondFactoryPackage.");
        return true;
    }

    function greeterFacetDFPkg() public returns (GreeterFacetDiamondFactoryPackage greeterFacetDFPkg_) {
        // _log("CraneFixture:greeterFacetDFPkg():: Entering function.");
        // _log("Checking if GreeterFacetDiamondFactoryPackage is declared.");
        if (address(_greeterFacetDFPkg) == address(0)) {
            // _log("GreeterFacetDiamondFactoryPackage is not declared, deploying...");
            greeterFacetDFPkg_ = GreeterFacetDiamondFactoryPackage(
                factory().create2(
                    GREETER_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE,
                    ""
                )
            );
            // _log("GreeterFacetDiamondFactoryPackage deployed @ ", address(greeterFacetDFPkg_));
            // _log("Setting greeter facet diamond factory package for later use.");
            greeterFacetDFPkg(greeterFacetDFPkg_);
            // _log("Greeter facet diamond factory package set for later use.");
        }
        // _log("Returning value from storage presuming it would have been set based on chain state.");
        // _log("CraneFixture:greeterFacetDFPkg():: Exiting function.");
        return _greeterFacetDFPkg;
    }

}
