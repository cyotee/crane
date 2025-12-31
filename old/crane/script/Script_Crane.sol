// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase} from 
// TestBase
"forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe} from 
// StdCheats
"forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "@crane/src/constants/Constants.sol";
import "contracts/crane/constants/CraneINITCODE.sol";
// import { betterconsole as console } from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
// import {terminal as term} from "contracts/crane/utils/vm/foundry/tools/terminal.sol";
// import { LOCAL } from "contracts/crane/constants/networks/LOCAL.sol";
// import { ETHEREUM_MAIN } from "contracts/crane/constants/networks/ETHEREUM_MAIN.sol";
// import { ETHEREUM_SEPOLIA } from "contracts/crane/constants/networks/ETHEREUM_SEPOLIA.sol";
import {APE_CHAIN_MAIN} from "contracts/crane/constants/networks/APE_CHAIN_MAIN.sol";
// import { APE_CHAIN_CURTIS } from "contracts/crane/constants/networks/APE_CHAIN_CURTIS.sol";
import {Creation} from "contracts/crane/utils/Creation.sol";
// import { ICreate2CallbackFactory } from "contracts/crane/interfaces/ICreate2CallbackFactory.sol";
// import { Create2CallBackFactory } from "contracts/crane/factories/create2/callback/Create2CallBackFactory.sol";
// import { IPower } from "contracts/crane/interfaces/IPower.sol";
import {PowerCalculatorC2ATarget} from "contracts/crane/utils/math/power-calc/PowerCalculatorC2ATarget.sol";
import {ICreate3Aware} from "contracts/crane/interfaces/ICreate3Aware.sol";
import {
    IERC20MintBurnOperableFacetDFPkg,
    ERC20MintBurnOperableFacetDFPkg
} from "contracts/crane/token/ERC20/extensions/ERC20MintBurnOperableFacetDFPkg.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage} from 
// ERC20MintBurnOperableStorage
"contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";
import {IOwnableStorage} from 
// OwnableStorage
"contracts/crane/access/ownable/utils/OwnableStorage.sol";
// import { IUniswapV2Aware } from "contracts/crane/interfaces/IUniswapV2Aware.sol";
import {CamelotV2AwareFacet} from "contracts/crane/protocols/dexes/camelot/v2/CamelotV2AwareFacet.sol";
import {UniswapV2AwareFacet} from "contracts/crane/protocols/dexes/uniswap/v2/UniswapV2AwareFacet.sol";
import {IERC20MinterFacadeFacetDFPkg} from "contracts/crane/token/ERC20/ERC20MinterFacadeFacetDFPkg.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IERC20MinterFacade} from "contracts/crane/interfaces/IERC20MinterFacade.sol";
import {IDiamondFactoryPackage} from "contracts/crane/interfaces/IDiamondFactoryPackage.sol";

import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/src/utils/collections/sets/StringSetRepo.sol";

abstract contract Script_Crane is
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

    function run()
        public
        virtual
        override(ScriptBase_Crane_Factories, ScriptBase_Crane_ERC20, ScriptBase_Crane_ERC4626)
    {
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
    /*                       ERC20MinterFacadeFacetDFPkg                      */
    /* ---------------------------------------------------------------------- */

    function erc20MinterFacadeFacetDFPkg(uint256 chainid, ERC20MinterFacadeFacetDFPkg erc20MinterFacadeFacetDFPkg_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, ERC20_MINTER_FACADE_FACET_DFPKG_INITCODE_HASH, address(erc20MinterFacadeFacetDFPkg_));
        declare(builderKey_Crane(), "erc20MinterFacadeFacetDFPkg", address(erc20MinterFacadeFacetDFPkg_));
        return true;
    }

    function erc20MinterFacadeFacetDFPkg(ERC20MinterFacadeFacetDFPkg erc20MinterFacadeFacetDFPkg_)
        public
        virtual
        returns (bool)
    {
        erc20MinterFacadeFacetDFPkg(block.chainid, erc20MinterFacadeFacetDFPkg_);
        return true;
    }

    function erc20MinterFacadeFacetDFPkg(uint256 chainid)
        public
        view
        virtual
        returns (ERC20MinterFacadeFacetDFPkg erc20MinterFacadeFacetDFPkg_)
    {
        erc20MinterFacadeFacetDFPkg_ =
            ERC20MinterFacadeFacetDFPkg(chainInstance(chainid, ERC20_MINTER_FACADE_FACET_DFPKG_INITCODE_HASH));
        return erc20MinterFacadeFacetDFPkg_;
    }

    function erc20MinterFacadeFacetDFPkg(IERC20MinterFacadeFacetDFPkg.ERC20MinterFacadeFacetDFPkgInit memory pkgInit)
        public
        virtual
        returns (ERC20MinterFacadeFacetDFPkg erc20MinterFacadeFacetDFPkg_)
    {
        if (address(erc20MinterFacadeFacetDFPkg(block.chainid)) == address(0)) {
            erc20MinterFacadeFacetDFPkg_ = ERC20MinterFacadeFacetDFPkg(
                factory()
                    .create3(
                        ERC20_MINTER_FACADE_FACET_DFPKG_INITCODE,
                        abi.encode(pkgInit),
                        keccak256(abi.encode(type(ERC20MinterFacadeFacetDFPkg).name))
                    )
            );
            erc20MinterFacadeFacetDFPkg(block.chainid, erc20MinterFacadeFacetDFPkg_);
        }
        return erc20MinterFacadeFacetDFPkg(block.chainid);
    }

    function erc20MinterFacadeFacetDFPkg(
        // IFacet ownableFacet_
        bytes memory initData
    )
        public
        virtual
        returns (ERC20MinterFacadeFacetDFPkg erc20MinterFacadeFacetDFPkg_)
    {
        return erc20MinterFacadeFacetDFPkg(
            IERC20MinterFacadeFacetDFPkg.ERC20MinterFacadeFacetDFPkgInit({
                // ownableFacet: ownableFacet_
                ownableFacet: IFacet(abi.decode(initData, (address)))
            })
        );
    }

    function erc20MinterFacadeFacetDFPkg()
        public
        virtual
        returns (ERC20MinterFacadeFacetDFPkg erc20MinterFacadeFacetDFPkg_)
    {
        return erc20MinterFacadeFacetDFPkg(abi.encode(ownableFacet()));
    }

    /* ---------------------------------------------------------------------- */
    /*                           IERC20MinterFacade                           */
    /* ---------------------------------------------------------------------- */

    function erc20MinterFacade(uint256 chainid, IERC20MinterFacade erc20MinterFacade_) public virtual returns (bool) {
        registerInstance(chainid, ERC20_MINTER_FACADE_FACET_DFPKG_INITCODE_HASH, address(erc20MinterFacade_));
        declare(builderKey_Crane(), "erc20MinterFacade", address(erc20MinterFacade_));
        return true;
    }

    function erc20MinterFacade(IERC20MinterFacade erc20MinterFacade_) public virtual returns (bool) {
        return erc20MinterFacade(block.chainid, erc20MinterFacade_);
    }

    function erc20MinterFacade(uint256 chainid) public view virtual returns (IERC20MinterFacade erc20MinterFacade_) {
        erc20MinterFacade_ = IERC20MinterFacade(chainInstance(chainid, ERC20_MINTER_FACADE_FACET_DFPKG_INITCODE_HASH));
        return erc20MinterFacade_;
    }

    function erc20MinterFacade(IERC20MinterFacadeFacetDFPkg.ERC20MinterFacadePkgArgs memory pkgArgs)
        public
        virtual
        returns (IERC20MinterFacade erc20MinterFacade_)
    {
        if (address(erc20MinterFacade(block.chainid)) == address(0)) {
            erc20MinterFacade_ = IERC20MinterFacade(
                diamondFactory()
                    .deploy(IDiamondFactoryPackage(address(erc20MinterFacadeFacetDFPkg())), abi.encode(pkgArgs))
            );
            erc20MinterFacade(block.chainid, erc20MinterFacade_);
        }
        return erc20MinterFacade(block.chainid);
    }

    function erc20MinterFacade(address owner_, uint256 maxMintAmount)
        public
        virtual
        returns (IERC20MinterFacade erc20MinterFacade_)
    {
        return erc20MinterFacade(
            IERC20MinterFacadeFacetDFPkg.ERC20MinterFacadePkgArgs({owner: owner_, maxMint: maxMintAmount})
        );
    }

    function erc20MinterFacade(bytes memory maxMintAmount)
        public
        virtual
        returns (IERC20MinterFacade erc20MinterFacade_)
    {
        return erc20MinterFacade(owner(), abi.decode(maxMintAmount, (uint256)));
    }

    function erc20MinterFacade() public virtual returns (IERC20MinterFacade erc20MinterFacade_) {
        return erc20MinterFacade(abi.encode(TENK_WAD));
    }

    /* ---------------------------------------------------------------------- */
    /*                              OwnableFacet                              */
    /* ---------------------------------------------------------------------- */

    function ownableFacet(uint256 chainid, OwnableFacet ownableFacet_) public virtual returns (bool) {
        registerInstance(chainid, OWNABLE_FACET_INIT_CODE_HASH, address(ownableFacet_));
        declare(builderKey_Crane(), "ownableFacet", address(ownableFacet_));
        return true;
    }

    /**
     * @notice Declares the ownable facet for later use.
     * @param ownableFacet_ The ownable facet to declare.
     * @return true if the ownable facet was declared.
     */
    function ownableFacet(OwnableFacet ownableFacet_) public virtual returns (bool) {
        ownableFacet(block.chainid, ownableFacet_);
        return true;
    }

    function ownableFacet(uint256 chainid) public view virtual returns (OwnableFacet ownableFacet_) {
        ownableFacet_ = OwnableFacet(chainInstance(chainid, OWNABLE_FACET_INIT_CODE_HASH));
        return ownableFacet_;
    }

    /**
     * @notice Ownable facet.
     * @notice Exposes IOwnable so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply ownable modifiers.
     * @return ownableFacet_ The ownable facet.
     */
    function ownableFacet() public virtual returns (OwnableFacet ownableFacet_) {
        if (address(ownableFacet(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                ownableFacet_ = OwnableFacet(APE_CHAIN_MAIN.CRANE_OWNABLE_FACET_V1);
            } else {
                ownableFacet_ = OwnableFacet(
                    factory()
                        .create3(
                            OWNABLE_FACET_INIT_CODE,
                            abi.encode(
                                ICreate3Aware.CREATE3InitData({
                                    salt: keccak256(abi.encode(type(OwnableFacet).name)), initData: ""
                                })
                            ),
                            OWNABLE_FACET_SALT
                        )
                );
            }
            ownableFacet(ownableFacet_);
        }
        ownableFacet_ = ownableFacet(block.chainid);
        return ownableFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                              OperableFacet                             */
    /* ---------------------------------------------------------------------- */

    function operableFacet(uint256 chainid, OperableFacet operableFacet_) public virtual returns (bool) {
        registerInstance(chainid, OPERABLE_FACET_INIT_CODE_HASH, address(operableFacet_));
        declare(builderKey_Crane(), "operableFacet", address(operableFacet_));
        return true;
    }

    /**
     * @notice Declares the operable facet for later use.
     * @param operableFacet_ The operable facet to declare.
     * @return true if the operable facet was declared.
     */
    function operableFacet(OperableFacet operableFacet_) public virtual returns (bool) {
        operableFacet(block.chainid, operableFacet_);
        return true;
    }

    function operableFacet(uint256 chainid) public view virtual returns (OperableFacet operableFacet_) {
        operableFacet_ = OperableFacet(chainInstance(chainid, OPERABLE_FACET_INIT_CODE_HASH));
        return operableFacet_;
    }

    /**
     * @notice Operable facet.
     * @notice Exposes IOperable so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply operable modifiers.
     * @return operableFacet_ The operable facet.
     */
    function operableFacet() public virtual returns (OperableFacet operableFacet_) {
        if (address(operableFacet(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                operableFacet_ = OperableFacet(APE_CHAIN_MAIN.CRANE_OPERABLE_FACET_V1);
            } else {
                operableFacet_ = OperableFacet(
                    factory()
                        .create3(
                            OPERABLE_FACET_INIT_CODE,
                            abi.encode(
                                ICreate3Aware.CREATE3InitData({
                                    salt: keccak256(abi.encode(type(OperableFacet).name)), initData: ""
                                })
                            ),
                            OPERABLE_FACET_SALT
                        )
                );
            }
            operableFacet(operableFacet_);
        }
        return operableFacet(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                          OperableManagerFacet                          */
    /* ---------------------------------------------------------------------- */

    function operableManagerFacet(uint256 chainid, OperableManagerFacet operableManagerFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, OPERABLE_MANAGER_FACET_INITCODE_HASH, address(operableManagerFacet_));
        declare(builderKey_Crane(), "operableManagerFacet", address(operableManagerFacet_));
        return true;
    }

    function operableManagerFacet(OperableManagerFacet operableManagerFacet_) public virtual returns (bool) {
        operableManagerFacet(block.chainid, operableManagerFacet_);
        return true;
    }

    function operableManagerFacet(uint256 chainid)
        public
        view
        virtual
        returns (OperableManagerFacet operableManagerFacet_)
    {
        operableManagerFacet_ = OperableManagerFacet(chainInstance(chainid, OPERABLE_MANAGER_FACET_INITCODE_HASH));
        return operableManagerFacet_;
    }

    function operableManagerFacet() public virtual returns (OperableManagerFacet operableManagerFacet_) {
        if (address(operableManagerFacet(block.chainid)) == address(0)) {
            operableManagerFacet_ = OperableManagerFacet(
                factory()
                    .create3(
                        OPERABLE_MANAGER_FACET_INITCODE, "", keccak256(abi.encode(type(OperableManagerFacet).name))
                    )
            );
            operableManagerFacet(operableManagerFacet_);
        }
        operableManagerFacet_ = operableManagerFacet(block.chainid);
        return operableManagerFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                           ReentrancyLockFacet                          */
    /* ---------------------------------------------------------------------- */

    function reentrancyLockFacet(uint256 chainid, ReentrancyLockFacet reentrancyLockFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, REENTRANCY_LOCK_FACET_INIT_CODE_HASH, address(reentrancyLockFacet_));
        declare(builderKey_Crane(), "reentrancyLockFacet", address(reentrancyLockFacet_));
        return true;
    }

    /**
     * @notice Declares the reentrancy lock facet for later use.
     * @param reentrancyLockFacet_ The reentrancy lock facet to declare.
     * @return true if the reentrancy lock facet was declared.
     */
    function reentrancyLockFacet(ReentrancyLockFacet reentrancyLockFacet_) public virtual returns (bool) {
        reentrancyLockFacet(block.chainid, reentrancyLockFacet_);
        return true;
    }

    function reentrancyLockFacet(uint256 chainid)
        public
        view
        virtual
        returns (ReentrancyLockFacet reentrancyLockFacet_)
    {
        reentrancyLockFacet_ = ReentrancyLockFacet(chainInstance(chainid, REENTRANCY_LOCK_FACET_INIT_CODE_HASH));
    }

    /**
     * @notice Reentrancy lock facet.
     * @notice Exposes IReentrancyLock so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply reentrancy lock modifiers.
     * @return reentrancyLockFacet_ The reentrancy lock facet.
     */
    function reentrancyLockFacet() public virtual returns (ReentrancyLockFacet reentrancyLockFacet_) {
        if (address(reentrancyLockFacet(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                reentrancyLockFacet_ = ReentrancyLockFacet(APE_CHAIN_MAIN.CRANE_REENTRANCY_LOCK_FACET_V1);
            } else {
                reentrancyLockFacet_ = ReentrancyLockFacet(
                    factory()
                        .create3(
                            REENTRANCY_LOCK_FACET_INIT_CODE,
                            abi.encode(
                                ICreate3Aware.CREATE3InitData({
                                    salt: keccak256(abi.encode(type(ReentrancyLockFacet).name)), initData: ""
                                })
                            ),
                            keccak256(abi.encode(type(ReentrancyLockFacet).name))
                        )
                );
            }
            reentrancyLockFacet(reentrancyLockFacet_);
        }
        return reentrancyLockFacet(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                          DiamondCutFacetDFPkg                          */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function diamondCutFacetDFPkg(uint256 chainid, DiamondCutFacetDFPkg diamondCutFacetDFPkg_)
        public
        virtual
        returns (bool)
    {
        registerInstance(
            chainid, DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH, address(diamondCutFacetDFPkg_)
        );
        declare(builderKey_Crane(), "diamondCutFacetDFPkg", address(diamondCutFacetDFPkg_));
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function diamondCutFacetDFPkg(DiamondCutFacetDFPkg diamondCutFacetDFPkg_) public virtual returns (bool) {
        diamondCutFacetDFPkg(block.chainid, diamondCutFacetDFPkg_);
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function diamondCutFacetDFPkg(uint256 chainid)
        public
        view
        virtual
        returns (DiamondCutFacetDFPkg diamondCutFacetDFPkg_)
    {
        diamondCutFacetDFPkg_ =
            DiamondCutFacetDFPkg(chainInstance(chainid, DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE_HASH));
        return diamondCutFacetDFPkg_;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function diamondCutFacetDFPkg() public virtual returns (DiamondCutFacetDFPkg diamondCutFacetDFPkg_) {
        if (address(diamondCutFacetDFPkg(block.chainid)) == address(0)) {
            DiamondCutFacetDFPkg.DiamondCutPkgInit memory diamondCutPkgInit;
            diamondCutPkgInit.ownableFacet = ownableFacet();
            diamondCutFacetDFPkg_ = DiamondCutFacetDFPkg(
                factory()
                    .create3(
                        DIAMOND_CUT_FACET_DIAMOND_FACTORY_PACKAGE_INIT_CODE,
                        abi.encode(diamondCutPkgInit),
                        keccak256(abi.encode(type(DiamondCutFacetDFPkg).name))
                    )
            );
            diamondCutFacetDFPkg(diamondCutFacetDFPkg_);
        }
        diamondCutFacetDFPkg_ = diamondCutFacetDFPkg(block.chainid);
        return diamondCutFacetDFPkg_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        PowerCalculatorC2ATarget                        */
    /* ---------------------------------------------------------------------- */

    function powerCalculator(uint256 chainid, PowerCalculatorC2ATarget powerCalculator_) public virtual returns (bool) {
        registerInstance(chainid, POWER_CALC_INIT_CODE_HASH, address(powerCalculator_));
        declare(builderKey_Crane(), "powerCalculator", address(powerCalculator_));
        return true;
    }

    /**
     * @notice Declares the power calculator for later use.
     * @param powerCalculator_ The power calculator to declare.
     * @return true if the power calculator was declared.
     */
    function powerCalculator(PowerCalculatorC2ATarget powerCalculator_) public virtual returns (bool) {
        powerCalculator(block.chainid, powerCalculator_);
        return true;
    }

    function powerCalculator(uint256 chainid) public view virtual returns (PowerCalculatorC2ATarget powerCalculator_) {
        powerCalculator_ = PowerCalculatorC2ATarget(chainInstance(chainid, POWER_CALC_INIT_CODE_HASH));
        return powerCalculator_;
    }

    /**
     * @notice Power calculator.
     * @notice Does gas efficient power calculations.
     * @notice Externalized to save bytecode size.
     * @return powerCalculator_ The power calculator.
     */
    function powerCalculator() public virtual returns (PowerCalculatorC2ATarget powerCalculator_) {
        if (address(powerCalculator(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                powerCalculator_ = PowerCalculatorC2ATarget(APE_CHAIN_MAIN.CRANE_POWER_CALCULATOR_V1);
            } else {
                powerCalculator_ = PowerCalculatorC2ATarget(
                    factory()
                        .create3(POWER_CALC_INIT_CODE, "", keccak256(abi.encode(type(PowerCalculatorC2ATarget).name)))
                );
            }
            powerCalculator(powerCalculator_);
        }
        powerCalculator_ = powerCalculator(block.chainid);
        return powerCalculator_;
    }

    /* ---------------------------------------------------------------------- */
    /*                     ERC20MintBurnOperableFacetDFPkg                    */
    /* ---------------------------------------------------------------------- */

    function erc20MintBurnPkg(uint256 chainid, ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH, address(erc20MintBurnPkg_));
        declare(builderKey_Crane(), "erc20MintBurnPkg", address(erc20MintBurnPkg_));
        return true;
    }

    /**
     * @notice Declares the ERC20 mint burn operable facet diamond factory package for later use.
     * @param erc20MintBurnPkg_ The ERC20 mint burn operable facet diamond factory package to declare.
     * @return true if the ERC20 mint burn operable facet diamond factory package was declared.
     */
    function erc20MintBurnPkg(ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) public virtual returns (bool) {
        erc20MintBurnPkg(block.chainid, erc20MintBurnPkg_);
        return true;
    }

    function erc20MintBurnPkg(uint256 chainid)
        public
        view
        virtual
        returns (ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_)
    {
        erc20MintBurnPkg_ = ERC20MintBurnOperableFacetDFPkg(
            chainInstance(chainid, ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE_HASH)
        );
        return erc20MintBurnPkg_;
    }

    /**
     * @notice ERC20 mint burn operable facet diamond factory package.
     * @notice Deploys a DiamondFactorPackage for deploying ERC20MintBurnOperableFacet proxies.
     * @return erc20MintBurnPkg_ The ERC20 mint burn operable facet diamond factor package.
     */
    function erc20MintBurnPkg() public virtual returns (ERC20MintBurnOperableFacetDFPkg erc20MintBurnPkg_) {
        if (address(erc20MintBurnPkg(block.chainid)) == address(0)) {
            ERC20MintBurnOperableFacetDFPkg.PkgInit memory erc20MintPkgInit;
            erc20MintPkgInit.ownableFacet = ownableFacet();
            erc20MintPkgInit.operableFacet = operableFacet();
            erc20MintPkgInit.erc20PermitFacet = erc20PermitFacet();
            erc20MintBurnPkg_ = ERC20MintBurnOperableFacetDFPkg(
                factory()
                    .create3(
                        ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_INIT_CODE,
                        abi.encode(
                            IERC20MintBurnOperableFacetDFPkg.PkgInit({
                                ownableFacet: ownableFacet(),
                                operableFacet: operableFacet(),
                                erc20PermitFacet: erc20PermitFacet()
                            })
                        ),
                        ERC20_MINT_BURN_OPERABLE_FACET_DFPKG_SALT
                    )
            );
            erc20MintBurnPkg(erc20MintBurnPkg_);
        }
        erc20MintBurnPkg_ = erc20MintBurnPkg(block.chainid);
        return erc20MintBurnPkg_;
    }

    /* ---------------------------------------------------------------------- */
    /*                             IERC20MintBurn                             */
    /* ---------------------------------------------------------------------- */

    function erc20MintBurnOperable(address owner_, string memory name, string memory symbol, uint8 decimals)
        public
        virtual
        returns (IERC20MintBurn erc20_)
    {
        IOwnableStorage.OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = owner_;

        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenInit;
        tokenInit.ownableAccountInit = globalOwnableAccountInit;
        tokenInit.name = name;
        tokenInit.symbol = symbol;
        tokenInit.decimals = decimals;

        erc20_ = IERC20MintBurn(diamondFactory().deploy(erc20MintBurnPkg(), abi.encode(tokenInit)));
        return erc20_;
    }

    /* ---------------------------------------------------------------------- */
    /*                           CamelotV2AwareFacet                          */
    /* ---------------------------------------------------------------------- */

    function camelotV2AwareFacet(uint256 chainid, CamelotV2AwareFacet camelotV2Aware_) public virtual returns (bool) {
        registerInstance(chainid, CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH, address(camelotV2Aware_));
        declare(builderKey_Crane(), "camelotV2AwareFacet", address(camelotV2Aware_));
        return true;
    }

    function camelotV2AwareFacet(CamelotV2AwareFacet camelotV2Aware_) public virtual returns (bool) {
        camelotV2AwareFacet(block.chainid, camelotV2Aware_);
        return true;
    }

    function camelotV2AwareFacet(uint256 chainid) public view returns (CamelotV2AwareFacet camelotV2AwareFacet_) {
        camelotV2AwareFacet_ = CamelotV2AwareFacet(chainInstance(chainid, CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH));
        // console.log("Fixture_CamelotV2:camelotV2AwareFacet(uint256):: Exiting function.");
        return camelotV2AwareFacet_;
    }

    function camelotV2AwareFacet() public virtual returns (CamelotV2AwareFacet camelotV2AwareFacet_) {
        if (address(camelotV2AwareFacet(block.chainid)) == address(0)) {
            camelotV2AwareFacet_ = CamelotV2AwareFacet(
                factory()
                    .create3(
                        CAMELOT_V2_AWARE_FACET_INIT_CODE, "", keccak256(abi.encode(type(CamelotV2AwareFacet).name))
                    )
            );
            camelotV2AwareFacet(block.chainid, camelotV2AwareFacet_);
        }
        camelotV2AwareFacet_ = camelotV2AwareFacet(block.chainid);
        return camelotV2AwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                           UniswapV2AwareFacet                          */
    /* ---------------------------------------------------------------------- */

    function uniswapV2AwareFacet(uint256 chainid, UniswapV2AwareFacet uniswapV2Aware_) public virtual returns (bool) {
        registerInstance(chainid, UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH, address(uniswapV2Aware_));
        declare(builderKey_Crane(), "uniswapV2AwareFacet", address(uniswapV2Aware_));
        return true;
    }

    function uniswapV2AwareFacet(UniswapV2AwareFacet uniswapV2Aware_) public virtual returns (bool) {
        uniswapV2AwareFacet(block.chainid, uniswapV2Aware_);
        return true;
    }

    function uniswapV2AwareFacet(uint256 chainid) public view returns (UniswapV2AwareFacet) {
        return UniswapV2AwareFacet(chainInstance(chainid, UNISWAP_V2_AWARE_FACET_INIT_CODE_HASH));
    }

    function uniswapV2AwareFacet() public virtual returns (UniswapV2AwareFacet uniswapV2Aware_) {
        if (address(uniswapV2AwareFacet(block.chainid)) == address(0)) {
            uniswapV2Aware_ = UniswapV2AwareFacet(
                factory()
                    .create3(
                        UNISWAP_V2_AWARE_FACET_INIT_CODE,
                        "",
                        UNISWAP_V2_AWARE_FACET_SALT
                    )
            );
            uniswapV2AwareFacet(block.chainid, uniswapV2Aware_);
        }
        uniswapV2Aware_ = uniswapV2AwareFacet(block.chainid);
        return uniswapV2Aware_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        BalancerV3VaultAwareFacet                       */
    /* ---------------------------------------------------------------------- */

    function balancerV3VaultAwareFacet(uint256 chainid, BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH, address(balancerV3VaultAwareFacet_));
        declare(builderKey_Crane(), "balancerV3VaultAwareFacet", address(balancerV3VaultAwareFacet_));
        return true;
    }

    function balancerV3VaultAwareFacet(BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_)
        public
        virtual
        returns (bool)
    {
        balancerV3VaultAwareFacet(block.chainid, balancerV3VaultAwareFacet_);
        return true;
    }

    function balancerV3VaultAwareFacet(uint256 chainid)
        public
        view
        returns (BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_)
    {
        balancerV3VaultAwareFacet_ =
            BalancerV3VaultAwareFacet(chainInstance(chainid, BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE_HASH));
        return balancerV3VaultAwareFacet_;
    }

    function balancerV3VaultAwareFacet() public virtual returns (BalancerV3VaultAwareFacet balancerV3VaultAwareFacet_) {
        if (address(balancerV3VaultAwareFacet(block.chainid)) == address(0)) {
            balancerV3VaultAwareFacet_ = BalancerV3VaultAwareFacet(
                factory()
                    .create3(
                        BALANCER_V3_VAULT_AWARE_FACET_INIT_CODE,
                        "",
                        BALANCER_V3_VAULT_AWARE_FACET_SALT
                    )
            );
            balancerV3VaultAwareFacet(block.chainid, balancerV3VaultAwareFacet_);
        }
        balancerV3VaultAwareFacet_ = balancerV3VaultAwareFacet(block.chainid);
        return balancerV3VaultAwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                     BetterBalancerV3PoolTokenFacet                     */
    /* ---------------------------------------------------------------------- */

    function betterBalancerV3PoolTokenFacet(
        uint256 chainid,
        BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainid, BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH, address(betterBalancerV3PoolTokenFacet_)
        );
        declare(builderKey_Crane(), "betterBalancerV3PoolTokenFacet", address(betterBalancerV3PoolTokenFacet_));
        return true;
    }

    function betterBalancerV3PoolTokenFacet(BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_)
        public
        virtual
        returns (bool)
    {
        betterBalancerV3PoolTokenFacet(block.chainid, betterBalancerV3PoolTokenFacet_);
        return true;
    }

    function betterBalancerV3PoolTokenFacet(uint256 chainid)
        public
        view
        returns (BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_)
    {
        betterBalancerV3PoolTokenFacet_ =
            BetterBalancerV3PoolTokenFacet(chainInstance(chainid, BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE_HASH));
        return betterBalancerV3PoolTokenFacet_;
    }

    function betterBalancerV3PoolTokenFacet()
        public
        virtual
        returns (BetterBalancerV3PoolTokenFacet betterBalancerV3PoolTokenFacet_)
    {
        if (address(betterBalancerV3PoolTokenFacet(block.chainid)) == address(0)) {
            betterBalancerV3PoolTokenFacet_ = BetterBalancerV3PoolTokenFacet(
                factory()
                    .create3(
                        BETTER_BALANCER_V3_POOL_TOKEN_FACET_INIT_CODE,
                        "",
                        BETTER_BALANCER_V3_POOL_TOKEN_FACET_SALT
                    )
            );
            betterBalancerV3PoolTokenFacet(block.chainid, betterBalancerV3PoolTokenFacet_);
        }
        betterBalancerV3PoolTokenFacet_ = betterBalancerV3PoolTokenFacet(block.chainid);
        return betterBalancerV3PoolTokenFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                      BalancerV3AuthenticationFacet                     */
    /* ---------------------------------------------------------------------- */

    function balancerV3AuthenticationFacet(
        uint256 chainid,
        BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainid, BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH, address(balancerV3AuthenticationFacet_)
        );
        declare(builderKey_Crane(), "balancerV3AuthenticationFacet", address(balancerV3AuthenticationFacet_));
        return true;
    }

    function balancerV3AuthenticationFacet(BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_)
        public
        virtual
        returns (bool)
    {
        balancerV3AuthenticationFacet(block.chainid, balancerV3AuthenticationFacet_);
        return true;
    }

    function balancerV3AuthenticationFacet(uint256 chainid)
        public
        view
        returns (BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_)
    {
        balancerV3AuthenticationFacet_ =
            BalancerV3AuthenticationFacet(chainInstance(chainid, BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE_HASH));
        return balancerV3AuthenticationFacet_;
    }

    function balancerV3AuthenticationFacet()
        public
        virtual
        returns (BalancerV3AuthenticationFacet balancerV3AuthenticationFacet_)
    {
        if (address(balancerV3AuthenticationFacet(block.chainid)) == address(0)) {
            balancerV3AuthenticationFacet_ = BalancerV3AuthenticationFacet(
                factory()
                    .create3(
                        BALANCER_V3_AUTHENTICATION_FACET_INIT_CODE,
                        "",
                        BALANCER_V3_AUTHENTICATION_FACET_SALT
                    )
            );
            balancerV3AuthenticationFacet(block.chainid, balancerV3AuthenticationFacet_);
        }
        balancerV3AuthenticationFacet_ = balancerV3AuthenticationFacet(block.chainid);
        return balancerV3AuthenticationFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*               BalancedLiquidityInvariantRatioBoundsFacet               */
    /* ---------------------------------------------------------------------- */

    function balancedLiquidityInvariantRatioBoundsFacet(
        uint256 chainid,
        BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainid,
            BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH,
            address(balancedLiquidityInvariantRatioBoundsFacet_)
        );
        declare(
            builderKey_Crane(),
            "balancedLiquidityInvariantRatioBoundsFacet",
            address(balancedLiquidityInvariantRatioBoundsFacet_)
        );
        return true;
    }

    function balancedLiquidityInvariantRatioBoundsFacet(BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_)
        public
        virtual
        returns (bool)
    {
        balancedLiquidityInvariantRatioBoundsFacet(block.chainid, balancedLiquidityInvariantRatioBoundsFacet_);
        return true;
    }

    function balancedLiquidityInvariantRatioBoundsFacet(uint256 chainid)
        public
        view
        returns (BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_)
    {
        balancedLiquidityInvariantRatioBoundsFacet_ = BalancedLiquidityInvariantRatioBoundsFacet(
            chainInstance(chainid, BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH)
        );
        return balancedLiquidityInvariantRatioBoundsFacet_;
    }

    function balancedLiquidityInvariantRatioBoundsFacet()
        public
        virtual
        returns (BalancedLiquidityInvariantRatioBoundsFacet balancedLiquidityInvariantRatioBoundsFacet_)
    {
        if (address(balancedLiquidityInvariantRatioBoundsFacet(block.chainid)) == address(0)) {
            balancedLiquidityInvariantRatioBoundsFacet_ = BalancedLiquidityInvariantRatioBoundsFacet(
                factory()
                    .create3(
                        BALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE,
                        "",
                        keccak256(abi.encode(type(BalancedLiquidityInvariantRatioBoundsFacet).name))
                    )
            );
            balancedLiquidityInvariantRatioBoundsFacet(block.chainid, balancedLiquidityInvariantRatioBoundsFacet_);
        }
        balancedLiquidityInvariantRatioBoundsFacet_ = balancedLiquidityInvariantRatioBoundsFacet(block.chainid);
        return balancedLiquidityInvariantRatioBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                  StandardSwapFeePercentageBoundsFacet                  */
    /* ---------------------------------------------------------------------- */

    function standardSwapFeePercentageBoundsFacet(
        uint256 chainid,
        StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainid,
            STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH,
            address(standardSwapFeePercentageBoundsFacet_)
        );
        declare(
            builderKey_Crane(), "standardSwapFeePercentageBoundsFacet", address(standardSwapFeePercentageBoundsFacet_)
        );
        return true;
    }

    function standardSwapFeePercentageBoundsFacet(StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_)
        public
        virtual
        returns (bool)
    {
        standardSwapFeePercentageBoundsFacet(block.chainid, standardSwapFeePercentageBoundsFacet_);
        return true;
    }

    function standardSwapFeePercentageBoundsFacet(uint256 chainid)
        public
        view
        returns (StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_)
    {
        standardSwapFeePercentageBoundsFacet_ = StandardSwapFeePercentageBoundsFacet(
            chainInstance(chainid, STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH)
        );
        return standardSwapFeePercentageBoundsFacet_;
    }

    function standardSwapFeePercentageBoundsFacet()
        public
        virtual
        returns (StandardSwapFeePercentageBoundsFacet standardSwapFeePercentageBoundsFacet_)
    {
        if (address(standardSwapFeePercentageBoundsFacet(block.chainid)) == address(0)) {
            standardSwapFeePercentageBoundsFacet_ = StandardSwapFeePercentageBoundsFacet(
                factory()
                    .create3(
                        STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE,
                        "",
                        STANDARD_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_SALT
                    )
            );
            standardSwapFeePercentageBoundsFacet(block.chainid, standardSwapFeePercentageBoundsFacet_);
        }
        standardSwapFeePercentageBoundsFacet_ = standardSwapFeePercentageBoundsFacet(block.chainid);
        return standardSwapFeePercentageBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*          StandardUnbalancedLiquidityInvariantRatioBoundsFacet          */
    /* ---------------------------------------------------------------------- */

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet(
        uint256 chainid,
        StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainid,
            STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH,
            address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_)
        );
        declare(
            builderKey_Crane(),
            "standardUnbalancedLiquidityInvariantRatioBoundsFacet",
            address(standardUnbalancedLiquidityInvariantRatioBoundsFacet_)
        );
        return true;
    }

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet(StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_)
        public
        virtual
        returns (bool)
    {
        standardUnbalancedLiquidityInvariantRatioBoundsFacet(
            block.chainid, standardUnbalancedLiquidityInvariantRatioBoundsFacet_
        );
        return true;
    }

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet(uint256 chainid)
        public
        view
        returns (StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_)
    {
        standardUnbalancedLiquidityInvariantRatioBoundsFacet_ = StandardUnbalancedLiquidityInvariantRatioBoundsFacet(
            chainInstance(chainid, STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE_HASH)
        );
        return standardUnbalancedLiquidityInvariantRatioBoundsFacet_;
    }

    function standardUnbalancedLiquidityInvariantRatioBoundsFacet()
        public
        virtual
        returns (StandardUnbalancedLiquidityInvariantRatioBoundsFacet standardUnbalancedLiquidityInvariantRatioBoundsFacet_)
    {
        if (address(standardUnbalancedLiquidityInvariantRatioBoundsFacet(block.chainid)) == address(0)) {
            standardUnbalancedLiquidityInvariantRatioBoundsFacet_ = StandardUnbalancedLiquidityInvariantRatioBoundsFacet(
                factory()
                    .create3(
                        STANDARD_UNBALANCED_LIQUIDITY_INVARIANT_RATIO_BOUNDS_FACET_INIT_CODE,
                        "",
                        keccak256(abi.encode(type(StandardUnbalancedLiquidityInvariantRatioBoundsFacet).name))
                    )
            );
            standardUnbalancedLiquidityInvariantRatioBoundsFacet(
                block.chainid, standardUnbalancedLiquidityInvariantRatioBoundsFacet_
            );
        }
        standardUnbalancedLiquidityInvariantRatioBoundsFacet_ =
            standardUnbalancedLiquidityInvariantRatioBoundsFacet(block.chainid);
        return standardUnbalancedLiquidityInvariantRatioBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                    ZeroSwapFeePercentageBoundsFacet                    */
    /* ---------------------------------------------------------------------- */

    function zeroSwapFeePercentageBoundsFacet(
        uint256 chainid,
        ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainid, ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH, address(zeroSwapFeePercentageBoundsFacet_)
        );
        declare(builderKey_Crane(), "zeroSwapFeePercentageBoundsFacet", address(zeroSwapFeePercentageBoundsFacet_));
        return true;
    }

    function zeroSwapFeePercentageBoundsFacet(ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_)
        public
        virtual
        returns (bool)
    {
        zeroSwapFeePercentageBoundsFacet(block.chainid, zeroSwapFeePercentageBoundsFacet_);
        return true;
    }

    function zeroSwapFeePercentageBoundsFacet(uint256 chainid)
        public
        view
        returns (ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_)
    {
        zeroSwapFeePercentageBoundsFacet_ = ZeroSwapFeePercentageBoundsFacet(
            chainInstance(chainid, ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE_HASH)
        );
        return zeroSwapFeePercentageBoundsFacet_;
    }

    function zeroSwapFeePercentageBoundsFacet()
        public
        virtual
        returns (ZeroSwapFeePercentageBoundsFacet zeroSwapFeePercentageBoundsFacet_)
    {
        if (address(zeroSwapFeePercentageBoundsFacet(block.chainid)) == address(0)) {
            zeroSwapFeePercentageBoundsFacet_ = ZeroSwapFeePercentageBoundsFacet(
                factory()
                    .create3(
                        ZERO_SWAP_FEE_PERCENTAGE_BOUNDS_FACET_INIT_CODE,
                        "",
                        keccak256(abi.encode(type(ZeroSwapFeePercentageBoundsFacet).name))
                    )
            );
            zeroSwapFeePercentageBoundsFacet(block.chainid, zeroSwapFeePercentageBoundsFacet_);
        }
        zeroSwapFeePercentageBoundsFacet_ = zeroSwapFeePercentageBoundsFacet(block.chainid);
        return zeroSwapFeePercentageBoundsFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                          DefaultPoolInfoFacet                          */
    /* ---------------------------------------------------------------------- */

    function defaultPoolInfoFacet(uint256 chainId, DefaultPoolInfoFacet defaultPoolInfoFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainId, DEFAULT_POOL_INFO_FACET_INITCODE_HASH, address(defaultPoolInfoFacet_));
        declare(builderKey_Crane(), "defaultPoolInfoFacet", address(defaultPoolInfoFacet_));
        return true;
    }

    function defaultPoolInfoFacet(DefaultPoolInfoFacet defaultPoolInfoFacet_) public virtual returns (bool) {
        defaultPoolInfoFacet(block.chainid, defaultPoolInfoFacet_);
        return true;
    }

    function defaultPoolInfoFacet(uint256 chainId) public view returns (DefaultPoolInfoFacet defaultPoolInfoFacet_) {
        defaultPoolInfoFacet_ = DefaultPoolInfoFacet(chainInstance(chainId, DEFAULT_POOL_INFO_FACET_INITCODE_HASH));
        return defaultPoolInfoFacet_;
    }

    function defaultPoolInfoFacet() public virtual returns (DefaultPoolInfoFacet defaultPoolInfoFacet_) {
        if (address(defaultPoolInfoFacet(block.chainid)) == address(0)) {
            defaultPoolInfoFacet_ = DefaultPoolInfoFacet(
                factory()
                    .create3(
                        DEFAULT_POOL_INFO_FACET_INITCODE,
                        "",
                        DEFAULT_POOL_INFO_FACET_SALT
                    )
            );
            defaultPoolInfoFacet(block.chainid, defaultPoolInfoFacet_);
        }
        defaultPoolInfoFacet_ = defaultPoolInfoFacet(block.chainid);
        return defaultPoolInfoFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                    BalancerV3ERC4626AdaptorPoolFacet                   */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolFacet(
        uint256 chainId,
        BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH, address(balancerV3ERC4626AdaptorPoolFacet_)
        );
        declare(builderKey_Crane(), "balancerV3ERC4626AdaptorPoolFacet", address(balancerV3ERC4626AdaptorPoolFacet_));
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolFacet(BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_)
        public
        virtual
        returns (bool)
    {
        balancerV3ERC4626AdaptorPoolFacet(block.chainid, balancerV3ERC4626AdaptorPoolFacet_);
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolFacet(uint256 chainId)
        public
        view
        returns (BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_)
    {
        balancerV3ERC4626AdaptorPoolFacet_ = BalancerV3ERC4626AdaptorPoolFacet(
            chainInstance(chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE_HASH)
        );
        return balancerV3ERC4626AdaptorPoolFacet_;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolFacet()
        public
        virtual
        returns (BalancerV3ERC4626AdaptorPoolFacet balancerV3ERC4626AdaptorPoolFacet_)
    {
        if (address(balancerV3ERC4626AdaptorPoolFacet(block.chainid)) == address(0)) {
            balancerV3ERC4626AdaptorPoolFacet_ = BalancerV3ERC4626AdaptorPoolFacet(
                factory()
                    .create3(
                        BALANCER_V3_ERC4626_ADAPTOR_POOL_FACET_INITCODE,
                        "",
                        keccak256(abi.encode(type(BalancerV3ERC4626AdaptorPoolFacet).name))
                    )
            );
            balancerV3ERC4626AdaptorPoolFacet(block.chainid, balancerV3ERC4626AdaptorPoolFacet_);
        }
        balancerV3ERC4626AdaptorPoolFacet_ = balancerV3ERC4626AdaptorPoolFacet(block.chainid);
        return balancerV3ERC4626AdaptorPoolFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                 BalancerV3ERC4626AdaptorPoolHooksFacet                 */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolHooksFacet(
        uint256 chainId,
        /// forge-lint: disable-next-line(mixed-case-variable)
        BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_
    ) public virtual returns (bool) {
        registerInstance(
            chainId,
            BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH,
            address(balancerV3ERC4626AdaptorPoolHooksFacet_)
        );
        declare(
            builderKey_Crane(),
            "balancerV3ERC4626AdaptorPoolHooksFacet",
            address(balancerV3ERC4626AdaptorPoolHooksFacet_)
        );
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolHooksFacet(
        /// forge-lint: disable-next-line(mixed-case-variable)
        BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_
    ) public virtual returns (bool) {
        balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid, balancerV3ERC4626AdaptorPoolHooksFacet_);
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolHooksFacet(uint256 chainId)
        public
        view
        returns (
            /// forge-lint: disable-next-line(mixed-case-variable)
            BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_
        )
    {
        balancerV3ERC4626AdaptorPoolHooksFacet_ = BalancerV3ERC4626AdaptorPoolHooksFacet(
            chainInstance(chainId, BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE_HASH)
        );
        return balancerV3ERC4626AdaptorPoolHooksFacet_;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balancerV3ERC4626AdaptorPoolHooksFacet()
        public
        virtual
        returns (
            /// forge-lint: disable-next-line(mixed-case-variable)
            BalancerV3ERC4626AdaptorPoolHooksFacet balancerV3ERC4626AdaptorPoolHooksFacet_
        )
    {
        if (address(balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid)) == address(0)) {
            balancerV3ERC4626AdaptorPoolHooksFacet_ = BalancerV3ERC4626AdaptorPoolHooksFacet(
                factory()
                    .create3(
                        BALANCER_V3_ERC4626_ADAPTOR_POOL_HOOKS_FACET_INITCODE,
                        "",
                        keccak256(abi.encode(type(BalancerV3ERC4626AdaptorPoolHooksFacet).name))
                    )
            );
            balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid, balancerV3ERC4626AdaptorPoolHooksFacet_);
        }
        balancerV3ERC4626AdaptorPoolHooksFacet_ = balancerV3ERC4626AdaptorPoolHooksFacet(block.chainid);
        return balancerV3ERC4626AdaptorPoolHooksFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            ERC4626AwareFacet                           */
    /* ---------------------------------------------------------------------- */

    function erc4626AwareFacet(uint256 chainId, ERC4626AwareFacet erc4626AwareFacet_) public virtual returns (bool) {
        registerInstance(chainId, ERC4626_AWARE_FACET_INITCODE_HASH, address(erc4626AwareFacet_));
        declare(builderKey_Crane(), "erc4626AwareFacet", address(erc4626AwareFacet_));
        return true;
    }

    function erc4626AwareFacet(ERC4626AwareFacet erc4626AwareFacet_) public virtual returns (bool) {
        erc4626AwareFacet(block.chainid, erc4626AwareFacet_);
        return true;
    }

    function erc4626AwareFacet(uint256 chainId) public view returns (ERC4626AwareFacet erc4626AwareFacet_) {
        erc4626AwareFacet_ = ERC4626AwareFacet(chainInstance(chainId, ERC4626_AWARE_FACET_INITCODE_HASH));
    }

    function erc4626AwareFacet() public virtual returns (ERC4626AwareFacet erc4626AwareFacet_) {
        if (address(erc4626AwareFacet(block.chainid)) == address(0)) {
            erc4626AwareFacet_ = ERC4626AwareFacet(
                factory().create3(ERC4626_AWARE_FACET_INITCODE, "", keccak256(abi.encode(type(ERC4626AwareFacet).name)))
            );
            erc4626AwareFacet(block.chainid, erc4626AwareFacet_);
        }
        erc4626AwareFacet_ = erc4626AwareFacet(block.chainid);
        return erc4626AwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            ERC5115ViewFacet                            */
    /* ---------------------------------------------------------------------- */

    function erc5115ViewFacet(uint256 chainId, ERC5115ViewFacet erc5115ViewFacet_) public virtual returns (bool) {
        registerInstance(chainId, ERC5115_VIEW_FACET_INITCODE_HASH, address(erc5115ViewFacet_));
        declare(builderKey_Crane(), "erc5115ViewFacet", address(erc5115ViewFacet_));
        return true;
    }

    function erc5115ViewFacet(ERC5115ViewFacet erc5115ViewFacet_) public virtual returns (bool) {
        erc5115ViewFacet(block.chainid, erc5115ViewFacet_);
        return true;
    }

    function erc5115ViewFacet(uint256 chainId) public view returns (ERC5115ViewFacet erc5115ViewFacet_) {
        erc5115ViewFacet_ = ERC5115ViewFacet(chainInstance(chainId, ERC5115_VIEW_FACET_INITCODE_HASH));
        return erc5115ViewFacet_;
    }

    function erc5115ViewFacet() public virtual returns (ERC5115ViewFacet erc5115ViewFacet_) {
        if (address(erc5115ViewFacet(block.chainid)) == address(0)) {
            erc5115ViewFacet_ = ERC5115ViewFacet(
                factory().create3(ERC5115_VIEW_FACET_INITCODE, "", keccak256(abi.encode(type(ERC5115ViewFacet).name)))
            );
            erc5115ViewFacet(block.chainid, erc5115ViewFacet_);
        }
        erc5115ViewFacet_ = erc5115ViewFacet(block.chainid);
        return erc5115ViewFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        ERC5115ExtensionViewFacet                       */
    /* ---------------------------------------------------------------------- */

    function erc5115ExtensionViewFacet(uint256 chainId, ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainId, ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH, address(erc5115ExtensionViewFacet_));
        declare(builderKey_Crane(), "erc5115ExtensionViewFacet", address(erc5115ExtensionViewFacet_));
        return true;
    }

    function erc5115ExtensionViewFacet(ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_)
        public
        virtual
        returns (bool)
    {
        erc5115ExtensionViewFacet(block.chainid, erc5115ExtensionViewFacet_);
        return true;
    }

    function erc5115ExtensionViewFacet(uint256 chainId)
        public
        view
        returns (ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_)
    {
        erc5115ExtensionViewFacet_ =
            ERC5115ExtensionViewFacet(chainInstance(chainId, ERC5115_EXTENSION_VIEW_FACET_INITCODE_HASH));
        return erc5115ExtensionViewFacet_;
    }

    function erc5115ExtensionViewFacet() public virtual returns (ERC5115ExtensionViewFacet erc5115ExtensionViewFacet_) {
        if (address(erc5115ExtensionViewFacet(block.chainid)) == address(0)) {
            erc5115ExtensionViewFacet_ = ERC5115ExtensionViewFacet(
                factory()
                    .create3(
                        ERC5115_EXTENSION_VIEW_FACET_INITCODE,
                        "",
                        keccak256(abi.encode(type(ERC5115ExtensionViewFacet).name))
                    )
            );
            erc5115ExtensionViewFacet(block.chainid, erc5115ExtensionViewFacet_);
        }
        erc5115ExtensionViewFacet_ = erc5115ExtensionViewFacet(block.chainid);
        return erc5115ExtensionViewFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                        PowerCalculatorAwareFacet                       */
    /* ---------------------------------------------------------------------- */

    function powerCalculatorAwareFacet(uint256 chainId, PowerCalculatorAwareFacet powerCalculatorAwareFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainId, POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH, address(powerCalculatorAwareFacet_));
        declare(builderKey_Crane(), "powerCalculatorAwareFacet", address(powerCalculatorAwareFacet_));
        return true;
    }

    function powerCalculatorAwareFacet(PowerCalculatorAwareFacet powerCalculatorAwareFacet_)
        public
        virtual
        returns (bool)
    {
        powerCalculatorAwareFacet(block.chainid, powerCalculatorAwareFacet_);
        return true;
    }

    function powerCalculatorAwareFacet(uint256 chainId)
        public
        view
        returns (PowerCalculatorAwareFacet powerCalculatorAwareFacet_)
    {
        powerCalculatorAwareFacet_ =
            PowerCalculatorAwareFacet(chainInstance(chainId, POWER_CALCULATOR_AWARE_FACET_INITCODE_HASH));
        return powerCalculatorAwareFacet_;
    }

    function powerCalculatorAwareFacet() public virtual returns (PowerCalculatorAwareFacet powerCalculatorAwareFacet_) {
        if (address(powerCalculatorAwareFacet(block.chainid)) == address(0)) {
            powerCalculatorAwareFacet_ = PowerCalculatorAwareFacet(
                factory()
                    .create3(
                        POWER_CALCULATOR_AWARE_FACET_INITCODE,
                        "",
                        keccak256(abi.encode(type(PowerCalculatorAwareFacet).name))
                    )
            );
            powerCalculatorAwareFacet(block.chainid, powerCalculatorAwareFacet_);
        }
        powerCalculatorAwareFacet_ = powerCalculatorAwareFacet(block.chainid);
        return powerCalculatorAwareFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                              VersionFacet                              */
    /* ---------------------------------------------------------------------- */

    function versionFacet(uint256 chainId, VersionFacet versionFacet_) public virtual returns (bool) {
        registerInstance(chainId, VERSION_FACET_INITCODE_HASH, address(versionFacet_));
        declare(builderKey_Crane(), "versionFacet", address(versionFacet_));
        return true;
    }

    function versionFacet(VersionFacet versionFacet_) public virtual returns (bool) {
        versionFacet(block.chainid, versionFacet_);
        return true;
    }

    function versionFacet(uint256 chainId) public view returns (VersionFacet versionFacet_) {
        versionFacet_ = VersionFacet(chainInstance(chainId, VERSION_FACET_INITCODE_HASH));
        return versionFacet_;
    }

    function versionFacet() public virtual returns (VersionFacet versionFacet_) {
        if (address(versionFacet(block.chainid)) == address(0)) {
            versionFacet_ = VersionFacet(factory().create3(VERSION_FACET_INITCODE, "", VERSION_FACET_SALT));
            versionFacet(block.chainid, versionFacet_);
        }
        versionFacet_ = versionFacet(block.chainid);
        return versionFacet_;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ERC721Facet                                */
    /* -------------------------------------------------------------------------- */

    function erc721Facet(uint256 chainId, ERC721Facet erc721Facet_) public virtual returns (bool) {
        registerInstance(chainId, ERC721_FACET_INITCODE_HASH, address(erc721Facet_));
        declare(builderKey_Crane(), "erc721Facet", address(erc721Facet_));
        return true;
    }

    function erc721Facet(ERC721Facet erc721Facet_) public virtual returns (bool) {
        erc721Facet(block.chainid, erc721Facet_);
        return true;
    }

    function erc721Facet(uint256 chainId) public view returns (ERC721Facet erc721Facet_) {
        erc721Facet_ = ERC721Facet(chainInstance(chainId, ERC721_FACET_INITCODE_HASH));
        return erc721Facet_;
    }

    function erc721Facet() public virtual returns (ERC721Facet erc721Facet_) {
        if (address(erc721Facet(block.chainid)) == address(0)) {
            erc721Facet_ = ERC721Facet(factory().create3(ERC721_FACET_INITCODE, "", ERC721_FACET_SALT));
            erc721Facet(block.chainid, erc721Facet_);
        }
        erc721Facet_ = erc721Facet(block.chainid);
        return erc721Facet_;
    }

    /* -------------------------------------------------------------------------- */
    /*                             ERC721MetadataFacet                            */
    /* -------------------------------------------------------------------------- */

    function erc721MetadataFacet(uint256 chainId, ERC721MetadataFacet erc721MetadataFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainId, ERC721_METADATA_FACET_INITCODE_HASH, address(erc721MetadataFacet_));
        declare(builderKey_Crane(), "erc721MetadataFacet", address(erc721MetadataFacet_));
        return true;
    }

    function erc721MetadataFacet(ERC721MetadataFacet erc721MetadataFacet_) public virtual returns (bool) {
        erc721MetadataFacet(block.chainid, erc721MetadataFacet_);
        return true;
    }

    function erc721MetadataFacet(uint256 chainId) public view returns (ERC721MetadataFacet erc721MetadataFacet_) {
        erc721MetadataFacet_ = ERC721MetadataFacet(chainInstance(chainId, ERC721_METADATA_FACET_INITCODE_HASH));
        return erc721MetadataFacet_;
    }

    function erc721MetadataFacet() public virtual returns (ERC721MetadataFacet erc721MetadataFacet_) {
        if (address(erc721MetadataFacet(block.chainid)) == address(0)) {
            erc721MetadataFacet_ = ERC721MetadataFacet(
                factory().create3(ERC721_METADATA_FACET_INITCODE, "", ERC721_METADATA_FACET_SALT)
            );
            erc721MetadataFacet(block.chainid, erc721MetadataFacet_);
        }
        erc721MetadataFacet_ = erc721MetadataFacet(block.chainid);
        return erc721MetadataFacet_;
    }

    /* -------------------------------------------------------------------------- */
    /*                            ERC721EnumeratedFacet                           */
    /* -------------------------------------------------------------------------- */

    function erc721EnumeratedFacet(uint256 chainId, ERC721EnumeratedFacet erc721EnumeratedFacet_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainId, ERC721_ENUMERATED_FACET_INITCODE_HASH, address(erc721EnumeratedFacet_));
        declare(builderKey_Crane(), "erc721EnumeratedFacet", address(erc721EnumeratedFacet_));
        return true;
    }

    function erc721EnumeratedFacet(ERC721EnumeratedFacet erc721EnumeratedFacet_) public virtual returns (bool) {
        erc721EnumeratedFacet(block.chainid, erc721EnumeratedFacet_);
        return true;
    }

    function erc721EnumeratedFacet(uint256 chainId)
        public
        view
        returns (ERC721EnumeratedFacet erc721EnumeratedFacet_)
    {
        erc721EnumeratedFacet_ = ERC721EnumeratedFacet(
            chainInstance(chainId, ERC721_ENUMERATED_FACET_INITCODE_HASH)
        );
        return erc721EnumeratedFacet_;
    }

    function erc721EnumeratedFacet() public virtual returns (ERC721EnumeratedFacet erc721EnumeratedFacet_) {
        if (address(erc721EnumeratedFacet(block.chainid)) == address(0)) {
            erc721EnumeratedFacet_ = ERC721EnumeratedFacet(
                factory().create3(ERC721_ENUMERATED_FACET_INITCODE, "", ERC721_ENUMERATED_FACET_SALT)
            );
            erc721EnumeratedFacet(block.chainid, erc721EnumeratedFacet_);
        }
        erc721EnumeratedFacet_ = erc721EnumeratedFacet(block.chainid);
        return erc721EnumeratedFacet_;
    }

}
