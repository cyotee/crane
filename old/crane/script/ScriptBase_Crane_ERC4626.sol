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
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

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
import {ScriptBase_Crane_Factories} from "./ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC4626DFPkg} from "contracts/crane/token/ERC20/extensions/ERC4626DFPkg.sol";

abstract contract ScriptBase_Crane_ERC4626 is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20
{
    function builderKey_Crane_ERC4626() public pure returns (string memory) {
        return "crane_erc4626";
    }

    function run() public virtual override(ScriptBase_Crane_Factories, ScriptBase_Crane_ERC20) {
        // ScriptBase_Crane_Factories.run();
        ScriptBase_Crane_ERC20.run();
    }

    /* ---------------------------------------------------------------------- */
    /*                            Builder Functions                           */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                                IERC4626                                */
    /* ---------------------------------------------------------------------- */

    function erc4626(IERC4626DFPkg.ERC4626DFPkgArgs memory pkgArgs) public virtual returns (IERC4626 erc4626_) {
        erc4626_ = IERC4626(diamondFactory().deploy(erc4626DFPkg(), abi.encode(pkgArgs)));
        declare(builderKey_Crane_ERC4626(), erc4626_.name(), address(erc4626_));
        return erc4626_;
    }

    function erc4626(address underlying, string memory name, string memory symbol, uint8 decimalsOffset)
        public
        virtual
        returns (IERC4626 erc4626_)
    {
        IERC4626DFPkg.ERC4626DFPkgArgs memory pkgArgs = IERC4626DFPkg.ERC4626DFPkgArgs({
            underlying: underlying, decimalsOffset: decimalsOffset, name: name, symbol: symbol
        });
        erc4626_ = erc4626(pkgArgs);
        return erc4626_;
    }

    function erc4626(address underlying, string memory name, string memory symbol)
        public
        virtual
        returns (IERC4626 erc4626_)
    {
        erc4626_ = erc4626(underlying, name, symbol, 0);
        return erc4626_;
    }

    function erc4626(address underlying) public virtual returns (IERC4626 erc4626_) {
        erc4626_ = erc4626(underlying, string.concat(IERC20(underlying).name(), " ERC4626 Vault"), "ERC4626", 0);
        return erc4626_;
    }

    function erc4626(address underlying, uint8 decimalsOffset) public virtual returns (IERC4626 erc4626_) {
        erc4626_ =
            erc4626(underlying, string.concat(IERC20(underlying).name(), " ERC4626 Vault"), "ERC4626", decimalsOffset);
        return erc4626_;
    }

    /* ---------------------------------------------------------------------- */
    /*                          Deployment Functions                          */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                              ERC4626Facet                              */
    /* ---------------------------------------------------------------------- */

    function erc4626Facet(uint256 chainId, ERC4626Facet erc4626Facet_) public virtual returns (bool) {
        registerInstance(chainId, ERC4626_FACET_INITCODE_HASH, address(erc4626Facet_));
        declare(builderKey_Crane_ERC4626(), "erc4626Facet", address(erc4626Facet_));
        return true;
    }

    function erc4626Facet(ERC4626Facet erc4626Facet_) public virtual returns (bool) {
        erc4626Facet(block.chainid, erc4626Facet_);
        return true;
    }

    function erc4626Facet(uint256 chainId) public view returns (ERC4626Facet erc4626Facet_) {
        erc4626Facet_ = ERC4626Facet(chainInstance(chainId, ERC4626_FACET_INITCODE_HASH));
        return erc4626Facet_;
    }

    function erc4626Facet() public virtual returns (ERC4626Facet erc4626Facet_) {
        if (address(erc4626Facet(block.chainid)) == address(0)) {
            erc4626Facet_ = ERC4626Facet(
                factory()
                    .create3(
                        ERC4626_FACET_INITCODE,
                        "",
                        ERC4626_FACET_SALT
                    )
            );
            erc4626Facet(block.chainid, erc4626Facet_);
        }
        erc4626Facet_ = erc4626Facet(block.chainid);
        return erc4626Facet_;
    }

    /* ---------------------------------------------------------------------- */
    /*                              ERC4626DFPkg                              */
    /* ---------------------------------------------------------------------- */

    function erc4626DFPkg(uint256 chainId, ERC4626DFPkg erc4626DFPkg_) public virtual returns (bool) {
        registerInstance(chainId, ERC4626_DFPKG_INITCODE_HASH, address(erc4626DFPkg_));
        declare(builderKey_Crane_ERC4626(), "erc4626DFPkg", address(erc4626DFPkg_));
        return true;
    }

    function erc4626DFPkg(ERC4626DFPkg erc4626DFPkg_) public virtual returns (bool) {
        erc4626DFPkg(block.chainid, erc4626DFPkg_);
        return true;
    }

    function erc4626DFPkg(uint256 chainId) public view returns (ERC4626DFPkg erc4626DFPkg_) {
        erc4626DFPkg_ = ERC4626DFPkg(chainInstance(chainId, ERC4626_DFPKG_INITCODE_HASH));
        return erc4626DFPkg_;
    }

    function erc4626DFPkg() public virtual returns (ERC4626DFPkg erc4626DFPkg_) {
        if (address(erc4626DFPkg(block.chainid)) == address(0)) {
            IERC4626DFPkg.ERC4626DFPkgInit memory init =
                IERC4626DFPkg.ERC4626DFPkgInit({erc20PermitFacet: erc20PermitFacet(), erc4626Facet: erc4626Facet()});
            erc4626DFPkg_ = ERC4626DFPkg(
                factory()
                    .create3(
                        ERC4626_DFPKG_INITCODE,
                        abi.encode(init),
                        ERC4626_DFPKG_SALT
                    )
            );
            erc4626DFPkg(block.chainid, erc4626DFPkg_);
        }
        erc4626DFPkg_ = erc4626DFPkg(block.chainid);
        return erc4626DFPkg_;
    }
}
