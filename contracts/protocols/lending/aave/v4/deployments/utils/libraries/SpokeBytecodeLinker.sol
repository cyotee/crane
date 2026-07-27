// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

import {Vm} from "forge-std/Vm.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {Create2Utils} from "./Create2Utils.sol";

/// @notice Deploy LiquidationLogic and link SpokeInstance creation bytecode for BC / forge deploys.
library SpokeBytecodeLinker {
    using stdJson for string;

    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    /// @dev solc placeholder for LiquidationLogic (matches SpokeInstance artifact).
    string internal constant LIQUIDATION_LOGIC_PLACEHOLDER = "__$329ad157ba4e68d2f4f45d82720084bf07$__";

    bytes32 internal constant LIQUIDATION_LOGIC_SALT = bytes32(0);

    string internal constant SPOKE_ARTIFACT = "out/SpokeInstance.sol/SpokeInstance.json";
    string internal constant LIB_ARTIFACT_PATH =
        "contracts/protocols/lending/aave/v4/spoke/libraries/LiquidationLogic.sol:LiquidationLogic";

    /// @notice Deploy LiquidationLogic via CREATE2 (idempotent) and return linked Spoke creation code.
    function deployLiquidationLogicAndLinkSpoke()
        internal
        returns (address liquidationLogic, bytes memory linkedSpokeBytecode)
    {
        Create2Utils.ensureCreate2Factory();
        bytes memory libBytecode = VM.getCode(LIB_ARTIFACT_PATH);
        liquidationLogic = Create2Utils.create2DeployOrGet(LIQUIDATION_LOGIC_SALT, libBytecode);
        linkedSpokeBytecode = linkedSpokeCreationCode(liquidationLogic);
    }

    /// @notice FOUNDRY_LIBRARIES env line (Crane path) for operator recompile.
    function foundryLibrariesEnv(address liquidationLogic) internal view returns (string memory) {
        return string.concat(
            "FOUNDRY_LIBRARIES=contracts/protocols/lending/aave/v4/spoke/libraries/LiquidationLogic.sol:LiquidationLogic:",
            VM.toString(liquidationLogic)
        );
    }

    /// @notice Load SpokeInstance artifact object, replace library placeholder, parse to bytes.
    function linkedSpokeCreationCode(address liquidationLogic) internal view returns (bytes memory) {
        string memory json = VM.readFile(SPOKE_ARTIFACT);
        string memory object = json.readString(".bytecode.object");
        string memory addrHex = _strip0x(VM.toString(liquidationLogic));
        string memory linked = _replaceAll(object, LIQUIDATION_LOGIC_PLACEHOLDER, addrHex);
        bytes memory b = bytes(linked);
        if (b.length >= 2 && b[0] == "0" && (b[1] == "x" || b[1] == "X")) {
            return VM.parseBytes(linked);
        }
        return VM.parseBytes(string.concat("0x", linked));
    }

    function _strip0x(string memory s) private pure returns (string memory) {
        bytes memory b = bytes(s);
        if (b.length >= 2 && b[0] == "0" && (b[1] == "x" || b[1] == "X")) {
            bytes memory out = new bytes(b.length - 2);
            for (uint256 i; i < out.length; ++i) {
                out[i] = b[i + 2];
            }
            return string(out);
        }
        return s;
    }

    function _replaceAll(string memory hay, string memory from, string memory to) private pure returns (string memory) {
        bytes memory h = bytes(hay);
        bytes memory f = bytes(from);
        bytes memory t = bytes(to);
        if (f.length == 0) return hay;

        uint256 count;
        for (uint256 i; i + f.length <= h.length;) {
            if (_eq(h, i, f)) {
                unchecked {
                    ++count;
                    i += f.length;
                }
            } else {
                unchecked {
                    ++i;
                }
            }
        }
        if (count == 0) return hay; // already linked

        bytes memory out = new bytes(h.length - count * f.length + count * t.length);
        uint256 oi;
        for (uint256 i; i < h.length;) {
            if (i + f.length <= h.length && _eq(h, i, f)) {
                for (uint256 j; j < t.length; ++j) {
                    out[oi++] = t[j];
                }
                unchecked {
                    i += f.length;
                }
            } else {
                out[oi++] = h[i];
                unchecked {
                    ++i;
                }
            }
        }
        return string(out);
    }

    function _eq(bytes memory data, uint256 offset, bytes memory frag) private pure returns (bool) {
        for (uint256 j; j < frag.length; ++j) {
            if (data[offset + j] != frag[j]) return false;
        }
        return true;
    }
}
