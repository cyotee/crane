// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

// import "forge-std/console.sol";
// import "forge-std/console2.sol";

// import "contracts/crane/token/ERC20/interfaces/IERC20.sol";

// tag::ERC20Layout[]
// Named with Struct suffix to ensure no namespace collisions.
struct ERC20Layout {
    string name;
    string symbol;
    uint8 decimals;
    uint256 totalSupply;
    mapping(address account => uint256 balance) balanceOf;
    mapping(address account => mapping(address spender => uint256 approval)) allowances;
}
// end::ERC20Layout[]

// tag::ERC20Repo[]
/**
 * @title ERC20Repo Library to usage the related Struct as a storage layout.
 * @author cyotee doge <cyotee@syscoin.org>
 * @notice Simplifies Assembly operations upon the related Struct.
 */
library ERC20Repo {

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(ERC20Layout storage layout_) {
        assembly{layout_.slot := slot_}
    }
    // end::_layout[]

}
