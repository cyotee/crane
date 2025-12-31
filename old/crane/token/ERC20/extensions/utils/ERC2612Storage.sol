// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC5267Storage} from "contracts/crane/utils/cryptography/erc5267/ERC5267Storage.sol";
import {ERC20Storage} from "contracts/crane/token/ERC20/utils/ERC20Storage.sol";
import {IERC2612} from "contracts/crane/interfaces/IERC2612.sol";
import {ERC2612Layout, ERC2612Repo} from "contracts/crane/token/ERC20/extensions/utils/ERC2612Repo.sol";

/**
 * @title ERC2612Storage - Inheritable storage contract for ERC2612.
 * @author cyotee doge <doge.cyotee>
 * @dev Provides tracking nonces for addresses.
 * @dev Nonces will only increment.
 */
contract ERC2612Storage is ERC5267Storage, ERC20Storage {
    // Bind library to storage struct.
    using ERC2612Repo for bytes32;

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(ERC2612Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IERC2612).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    /**
     * @return Diamond storage struct bound to the declared "service" slot.
     */
    function _permit() internal pure virtual returns (ERC2612Layout storage) {
        return STORAGE_SLOT._layout();
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC2612(string memory name, string memory version, string memory symbol, uint8 decimals) internal {
        _initERC5267(
            // string memory name,
            name,
            // string memory version
            version
        );
        _initERC20(
            // string memory name,
            name,
            // string memory symbol,
            symbol,
            // uint8 decimals
            decimals
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC2612(
        string memory name,
        string memory version,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address recipient
    ) internal {
        _initERC5267(
            // string memory name,
            name,
            // string memory version
            version
        );
        _initERC20(
            // string memory name,
            name,
            // string memory symbol,
            symbol,
            // uint8 decimals,
            decimals,
            // uint256 totalSupply,
            totalSupply,
            // address recipient
            recipient
        );
    }

    /**
     * @dev The nonce used for an `account` is not the expected current nonce.
     */
    error InvalidAccountNonce(address account, uint256 currentNonce);

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(address owner) internal virtual returns (uint256) {
        // For each account, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.
        unchecked {
            // It is important to do x++ and not ++x here.
            return _permit().nonces[owner]++;
        }
    }

    /**
     * @dev Same as {_useNonce} but checking that `nonce` is the next valid for `owner`.
     */
    function _useCheckedNonce(address owner, uint256 nonce) internal virtual {
        uint256 current = _useNonce(owner);
        if (nonce != current) {
            revert InvalidAccountNonce(owner, current);
        }
    }
}
