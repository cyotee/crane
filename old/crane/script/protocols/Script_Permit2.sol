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
/*                                   Permit2                                  */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
// import { Permit2 } from "permit2/src/Permit2.sol";

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "@crane/src/constants/Constants.sol";
import "contracts/crane/constants/CraneINITCODE.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {ETHEREUM_MAIN} from "contracts/crane/constants/networks/ETHEREUM_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "contracts/crane/constants/networks/ETHEREUM_SEPOLIA.sol";
import {PERMIT2_CONSTANTS} from "contracts/crane/constants/protocols/utils/permit2/PERMIT2_CONSTANTS.sol";
import {BetterPermit2} from "contracts/crane/protocols/utils/permit2/BetterPermit2.sol";
// import { betterconsole as console } from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {IEIP712} from "contracts/crane/interfaces/IEIP712.sol";
import {IAllowanceTransfer} from "contracts/crane/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol";
import {Permit2AwareFacet} from "contracts/crane/protocols/utils/permit2/Permit2AwareFacet.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";

abstract contract Script_Permit2 is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories
{
    using EfficientHashLib for bytes;

    /// forge-lint: disable-next-line(mixed-case-function)
    function builderKey_Permit2() public pure returns (string memory) {
        return "permit2";
    }

    // function setUp() public virtual {}

    function run()
        public
        virtual
        override(
            // ScriptBase,
            ScriptBase_Crane_Factories
        )
    {
        declare(vm.getLabel(address(permit2())), address(permit2()));
    }

    function getPermitSignature(
        IEIP712 token,
        address owner_,
        address spender,
        uint256 amount,
        uint256 nonce,
        uint256 deadline,
        uint256 key
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        (v, r, s) = vm.sign(
            key,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(_PERMIT_TYPEHASH, owner_, spender, amount, nonce, deadline))
                )
            )
        );
    }

    function getPermit2Batch(address spender, address[] memory tokens, uint160 amount, uint48 expiration, uint48 nonce)
        internal
        view
        returns (IAllowanceTransfer.PermitBatch memory)
    {
        IAllowanceTransfer.PermitDetails[] memory details = new IAllowanceTransfer.PermitDetails[](tokens.length);

        for (uint256 i = 0; i < tokens.length; ++i) {
            details[i] = IAllowanceTransfer.PermitDetails({
                token: tokens[i], amount: amount, expiration: expiration, nonce: nonce
            });
        }

        return IAllowanceTransfer.PermitBatch({details: details, spender: spender, sigDeadline: block.timestamp + 100});
    }

    function getPermit2BatchSignature(
        IPermit2 permit2_,
        address spender,
        address[] memory tokens,
        uint160 amount,
        uint48 expiration,
        uint48 nonce,
        uint256 key
    ) internal view returns (bytes memory sig) {
        IAllowanceTransfer.PermitBatch memory permit = getPermit2Batch(spender, tokens, amount, expiration, nonce);
        bytes32[] memory permitHashes = new bytes32[](permit.details.length);
        for (uint256 i = 0; i < permit.details.length; ++i) {
            permitHashes[i] = keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, permit.details[i]));
        }
        bytes32 msgHash = abi.encodePacked(
                "\x19\x01",
                IEIP712(address(permit2_)).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        _PERMIT_BATCH_TYPEHASH,
                        keccak256(abi.encodePacked(permitHashes)),
                        permit.spender,
                        permit.sigDeadline
                    )
                )
            ).hash();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function getPermit2BatchSignature(
        address spender,
        address[] memory tokens,
        uint160 amount,
        uint48 expiration,
        uint48 nonce,
        uint256 key
    ) public virtual returns (bytes memory sig) {
        return getPermit2BatchSignature(permit2(), spender, tokens, amount, expiration, nonce, key);
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Permit2                                */
    /* ---------------------------------------------------------------------- */

    function permit2(uint256 chainid, IPermit2 permit2_) public virtual returns (bool) {
        registerInstance(chainid, PERMIT2_CONSTANTS.PERMIT2_INIT_CODE_HASH, address(permit2_));
        declare(builderKey_Permit2(), "permit2", address(permit2_));
        return true;
    }

    function permit2(IPermit2 permit2_) public virtual returns (bool) {
        permit2(block.chainid, permit2_);
        return true;
    }

    function permit2(uint256 chainid) public virtual returns (IPermit2 permit2_) {
        permit2_ = IPermit2(chainInstance(chainid, PERMIT2_CONSTANTS.PERMIT2_INIT_CODE_HASH));
    }

    function permit2() public virtual returns (IPermit2 permit2_) {
        if (address(permit2(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                permit2_ = IPermit2(ETHEREUM_MAIN.PERMIT2);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                permit2_ = IPermit2(ETHEREUM_SEPOLIA.PERMIT2);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                permit2_ = IPermit2(address(new BetterPermit2()));
            } else {
                permit2_ = IPermit2(address(new BetterPermit2()));
            }
            permit2(permit2_);
        }
        return permit2(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Permit2AwareFacet                           */
    /* ---------------------------------------------------------------------- */

    function permit2AwareFacet(uint256 chainId, Permit2AwareFacet permit2AwareFacet_) public virtual returns (bool) {
        registerInstance(chainId, PERMIT2_AWARE_FACET_INITCODE_HASH, address(permit2AwareFacet_));
        declare(builderKey_Permit2(), "permit2AwareFacet", address(permit2AwareFacet_));
        return true;
    }

    function permit2AwareFacet(Permit2AwareFacet permit2AwareFacet_) public virtual returns (bool) {
        permit2AwareFacet(block.chainid, permit2AwareFacet_);
        return true;
    }

    function permit2AwareFacet(uint256 chainId) public view returns (Permit2AwareFacet permit2AwareFacet_) {
        permit2AwareFacet_ = Permit2AwareFacet(chainInstance(chainId, PERMIT2_AWARE_FACET_INITCODE_HASH));
    }

    function permit2AwareFacet() public virtual returns (Permit2AwareFacet permit2AwareFacet_) {
        if (address(permit2AwareFacet(block.chainid)) == address(0)) {
            permit2AwareFacet_ = Permit2AwareFacet(
                factory()
                    .create3(
                        PERMIT2_AWARE_FACET_INITCODE,
                        "",
                        PERMIT2_AWARE_FACET_SALT
                    )
            );
            permit2AwareFacet(permit2AwareFacet_);
        }
        return permit2AwareFacet(block.chainid);
    }
}
