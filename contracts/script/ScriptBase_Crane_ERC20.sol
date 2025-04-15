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
import { ScriptBase_Crane_Factories } from "./ScriptBase_Crane_Factories.sol";
import { Creation } from "../utils/Creation.sol";
import { LOCAL } from "../constants/networks/LOCAL.sol";
import { ETHEREUM_MAIN } from "../constants/networks/ETHEREUM_MAIN.sol";
import { ETHEREUM_SEPOLIA } from "../constants/networks/ETHEREUM_SEPOLIA.sol";
import { APE_CHAIN_MAIN } from "../constants/networks/APE_CHAIN_MAIN.sol";
import { APE_CHAIN_CURTIS } from "../constants/networks/APE_CHAIN_CURTIS.sol";
import {
    IERC20PermitStorage,
    ERC20PermitStorage
} from "../token/ERC20/extensions/utils/ERC20PermitStorage.sol";
import {
    IERC20PermitDFPkg,
    ERC20PermitDFPkg
} from "../token/ERC20/extensions/ERC20PermitDFPkg.sol";
import {
    IERC20Storage,
    ERC20Storage
} from "../token/ERC20/utils/ERC20Storage.sol";
import {
    BetterIERC20 as IERC20
} from "../interfaces/BetterIERC20.sol";

contract ScriptBase_Crane_ERC20
is
    // CommonBase,
    // ScriptBase,
    // StdChains,
    // StdCheatsSafe,
    // StdUtils,
    // Script,
    // BetterScript,
    ScriptBase_Crane_Factories
{

    function builderKey_Crane_ERC20() public pure returns (string memory) {
        return "crane_erc20";
    }

    function run() public virtual override {
        ScriptBase_Crane_Factories.run();
        declare(vm.getLabel(address(erc20PermitFacet())), address(erc20PermitFacet()));
        declare(vm.getLabel(address(erc20PermitDFPkg())), address(erc20PermitDFPkg()));
    }
    
    /* ---------------------------------------------------------------------- */
    /*                            ERC20PermitFacet                            */
    /* ---------------------------------------------------------------------- */

    function erc20PermitFacet(
        uint256 chainid,
        ERC20PermitFacet erc20PermitFacet_
    ) public returns(bool) {
        registerInstance(chainid, ERC20_PERMIT_FACET_INIT_CODE_HASH, address(erc20PermitFacet_));
        declare(builderKey_Crane_ERC20(), "erc20PermitFacet", address(erc20PermitFacet_));
        return true;
    }   

    /**
     * @notice Declares the ERC20 permit facet for later use.
     * @param erc20PermitFacet_ The ERC20 permit facet to declare.
     * @return true if the ERC20 permit facet was declared.
     */
    function erc20PermitFacet(ERC20PermitFacet erc20PermitFacet_) public returns(bool) {
        erc20PermitFacet(block.chainid, erc20PermitFacet_);
        return true;
    }

    function erc20PermitFacet(uint256 chainid)
    public virtual view returns(ERC20PermitFacet erc20PermitFacet_) {
        erc20PermitFacet_ = ERC20PermitFacet(chainInstance(chainid, ERC20_PERMIT_FACET_INIT_CODE_HASH));
        return erc20PermitFacet_;
    }

    /**
     * @notice ERC20 permit facet.
     * @notice Exposes ERC20Permit so it can reused by proxies.
     * @notice minimizes the required bytecode for other targets to apply ERC20 permit modifiers.
     * @return erc20PermitFacet_ The ERC20 permit facet.
     */
    function erc20PermitFacet() public returns (ERC20PermitFacet erc20PermitFacet_) {
        if (address(erc20PermitFacet(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                erc20PermitFacet_ = ERC20PermitFacet(APE_CHAIN_MAIN.CRANE_ERC20_PERMIT_FACET_V1);
            } else {
                erc20PermitFacet_ = ERC20PermitFacet(
                    factory().create3(
                        ERC20_PERMIT_FACET_INIT_CODE, 
                        // abi.encode(ICreate3Aware.CREATE3InitData({
                        //     salt: keccak256(abi.encode(type(ERC20PermitFacet).name)),
                        //     initData: ""
                        // })),
                        "",
                        keccak256(abi.encode(type(ERC20PermitFacet).name))
                    )
                );
            }
            erc20PermitFacet(erc20PermitFacet_);
        }
        erc20PermitFacet_ = erc20PermitFacet(block.chainid);
        return erc20PermitFacet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            ERC20PermitDFPkg                            */
    /* ---------------------------------------------------------------------- */

    function erc20PermitDFPkg(
        uint256 chainid,
        ERC20PermitDFPkg erc20PermitDFPkg_
    ) public returns(bool) {
        registerInstance(chainid, ERC20_PERMIT_FACET_DFPKG_INIT_CODE_HASH, address(erc20PermitDFPkg_));
        declare(builderKey_Crane_ERC20(), "erc20PermitDFPkg", address(erc20PermitDFPkg_));
        return true;
    }

    /** 
     * @notice Declares the ERC20 permit package for later use.
     * @param erc20PermitDFPkg_ The ERC20 permit package to declare.
     * @return true if the ERC20 permit package was declared.
     */
    function erc20PermitDFPkg(ERC20PermitDFPkg erc20PermitDFPkg_) public returns(bool) {
        erc20PermitDFPkg(block.chainid, erc20PermitDFPkg_);
        return true;
    }

    function erc20PermitDFPkg(uint256 chainid)
    public virtual view returns(ERC20PermitDFPkg erc20PermitDFPkg_) {
        erc20PermitDFPkg_ = ERC20PermitDFPkg(chainInstance(chainid, ERC20_PERMIT_FACET_DFPKG_INIT_CODE_HASH));
        return erc20PermitDFPkg_;
    }

    /**
     * @notice ERC20 permit package.
     * @notice Deploys a DiamondFactorPackage for deploying ERC20PermitFacet proxies.
     * @return erc20PermitDFPkg_ The ERC20 permit package.
     */
    function erc20PermitDFPkg() public returns (ERC20PermitDFPkg erc20PermitDFPkg_) {
        if (address(erc20PermitDFPkg(block.chainid)) == address(0)) {
            IERC20PermitDFPkg.ERC20PermitDFPkgInit memory erc20PermitDFPkgInit;
            erc20PermitDFPkgInit.erc20PermitFacet = erc20PermitFacet();
            erc20PermitDFPkg_ = ERC20PermitDFPkg(
                factory().create3(
                    ERC20_PERMIT_FACET_DFPKG_INIT_CODE,
                    abi.encode(
                        IERC20PermitDFPkg.ERC20PermitDFPkgInit({
                            erc20PermitFacet: erc20PermitFacet()
                        })
                    ),
                    keccak256(abi.encode(type(ERC20PermitDFPkg).name))
                )
            );
            erc20PermitDFPkg(erc20PermitDFPkg_);
        }
        erc20PermitDFPkg_ = erc20PermitDFPkg(block.chainid);
        return erc20PermitDFPkg_;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IERC20                                 */
    /* ---------------------------------------------------------------------- */

    function erc20Permit(
        IERC20PermitDFPkg.ERC20PermitDFPkgArgs memory pkgArgs
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = IERC20(
            diamondFactory().deploy(
                erc20PermitDFPkg(),
                abi.encode(pkgArgs)
            )
        );
        vm.label(address(erc20_), erc20_.name());
        return erc20_;
    }

    function erc20Permit(
        IERC20PermitStorage.ERC20PermitTargetInit memory erc20PermitTargetInit
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            IERC20PermitDFPkg.ERC20PermitDFPkgArgs({
                erc20PermitTargetInit: erc20PermitTargetInit
            })
        );
        return erc20_;
    }

    function erc20Permit(
        IERC20Storage.ERC20StorageInit memory erc20StorageInit,
        string memory version
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            IERC20PermitStorage.ERC20PermitTargetInit({
                erc20Init: erc20StorageInit,
                version: version
            })
        );
    }

    function erc20Permit(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version,
        uint256 totalSupply,
        address recipient
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            IERC20Storage.ERC20StorageInit({
                name: name,
                symbol: symbol,
                decimals: decimals,
                totalSupply: totalSupply,
                recipient: recipient
            }),
            version
        );
    }

    function erc20Permit(
        string memory name,
        string memory symbol,
        uint8 decimals,
        string memory version
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            name,
            symbol,
            decimals,
            version,
            0,
            address(0)
        );
    }

    function erc20Permit(
        string memory name,
        string memory symbol,
        string memory version,
        uint256 totalSupply,
        address recipient
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            IERC20Storage.ERC20StorageInit({
                name: name,
                symbol: symbol,
                decimals: 18,
                totalSupply: totalSupply,
                recipient: recipient
            }),
            version
        );
    }

    function erc20Permit(
        string memory name,
        string memory symbol,
        string memory version
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            name,
            symbol,
            version,
            0,
            address(0)
        );
    }

    function erc20Permit(
        string memory name,
        string memory symbol
    ) public virtual returns (IERC20 erc20_) {
        erc20_ = erc20Permit(
            name,
            symbol,
            "1",
            0,
            address(0)
        );
    }

}