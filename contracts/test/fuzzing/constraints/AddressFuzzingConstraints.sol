// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-global-import
// solhint-disable state-visibility
// solhint-disable func-name-mixedcase
// import "forge-std/Test.sol";
// import "lib/forge-std/src/Test.sol";
// import "thefactory/collections/Collections.sol";
import "forge-std/StdCheats.sol";
import {FoundryVM} from "../../../utils/vm/foundry/FoundryVM.sol";
import {
    AddressSet,
    AddressSetRepo
} from "../../../utils/collections/sets/AddressSetRepo.sol";

struct AddressFuzzingLayout {
    AddressSet usedAddresses;
}

library AddressFuzzingRepo {

    // using Array for uint256;

    /* ------------------------- EMBEDDED LIBRARIES ------------------------- */

    // address constant ARRAY_ID = address(uint160(uint256(keccak256(type(Array).creationCode))));

    function slot(
        AddressFuzzingLayout storage table
    ) external pure returns(bytes32 slot_) {
        return _slot(table);
    }
    
    function _slot(
        AddressFuzzingLayout storage table
    ) internal pure returns(bytes32 slot_) {
        assembly{slot_ := table.slot}
    }
    
    function layout(
        bytes32 slot_
    ) external pure returns(AddressFuzzingLayout storage layout_) {
        return _layout(slot_);
    }
    
    function _layout(
        bytes32 storageRange
    ) internal pure returns(AddressFuzzingLayout storage layout_) {
        // storageRange ^= STORAGE_RANGE_OFFSET;
        assembly{layout_.slot := storageRange}
    }
}

/**
 * @dev This is an objectively better test.
 */
contract AddressFuzzingConstraints is FoundryVM, StdCheats {

    using AddressSetRepo for AddressSet;
    using AddressFuzzingRepo for AddressFuzzingLayout;

    /* ------------------------------ LIBRARIES ----------------------------- */

    // using ERC20Layout for ERC20Struct;

    /* ------------------------- EMBEDDED LIBRARIES ------------------------- */

    // TODO Replace with address of deployed library.
    // Normally handled by usage for storage slot.
    // Included to facilitate automated audits.
    // address constant AddressFuzzingRepo_ID = address(ERC20Layout);
    address constant AddressFuzzingRepo_ID = address(uint160(uint256(keccak256(type(AddressFuzzingRepo).creationCode))));

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */
  
    // Defines the default offset applied to all provided storage ranges for use when operating on a struct instance.
    // Subtract 1 from hashed value to ensure future usage of relevant library address.
    bytes32 constant internal AddressFuzzingRepo_STORAGE_RANGE_OFFSET = bytes32(uint256(keccak256(abi.encode(AddressFuzzingRepo_ID))) - 1);

    // The default storage range to use with the Layout libraries consumed by this library.
    // Service libraries are expected to coordinate operations in relation to a interface between other Services and Repos.
    // bytes32 internal constant ERC20_STORAGE_RANGE = type(IERC20).interfaceId;
    // bytes32 internal constant ERC20_STORAGE_SLOT = ERC20_STORAGE_RANGE_OFFSET;

    // tag::_erc20()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistant storage usage.
     * @return The default storage range used with repos.
     */
    function _addrFuzz(bytes32 slot)
    internal pure virtual returns(AddressFuzzingLayout storage) {
        return AddressFuzzingRepo._layout(AddressFuzzingRepo_STORAGE_RANGE_OFFSET ^ slot);
    }

    function _usedAddrs(address context) internal view returns(AddressSet storage) {
        return _addrFuzz(keccak256(abi.encode(address(context)))).usedAddresses;
    }

    function _usedAddrs() internal view returns(AddressSet storage) {
        return _usedAddrs(address(this));
    }

    function declareUsed(address used)
    public {
        _usedAddrs()._add(used);
    }

    function usedAddrs(address context) public view returns(address[] memory) {
        return _usedAddrs(context)._values();
    }

    function usedAddrs() public view returns(address[] memory) {
        return _usedAddrs(address(this))._values();
    }

    function _tempUsedAddrs(
        address[] memory values
    ) internal view returns(AddressSet storage) {
        return _addrFuzz(keccak256(abi.encode(values))).usedAddresses;
    }

    function deDup(
        address[] memory values
    ) public returns(address[] memory) {
        _tempUsedAddrs(values)._add(values);
        return _tempUsedAddrs(values)._values();
    }

    modifier isValid(
        address check
    ) {
        _notZeroAddr(check);
        _notThis(check);
        _notPreCompile(check);
        _notUsed(check);
        _;
    }

    modifier notZeroAddr(
        address check
    ) {
        _notZeroAddr(check);
        _;
    }

    modifier areValid(
        address[] memory check
    ) {
        // for(uint256 cursor = 0; cursor < check.length; cursor++) {
        //     _notZeroAddr(check[cursor]);
        //     _notThis(check[cursor]);
        //     _notPreCompile(check[cursor]);
        // }
        _areValid(check);
        _;
    }

    function _areValid(
        address[] memory check
    ) internal view {
        for(uint256 cursor = 0; cursor < check.length; cursor++) {
            _notZeroAddr(check[cursor]);
            _notThis(check[cursor]);
            _notPreCompile(check[cursor]);
            _notUsed(check[cursor]);
        }
    }

    function _notZeroAddr(
        address check
    ) internal pure {
        vm.assume(check != address(0));
    }

    function _notThis(
        address check
    ) internal view {
        vm.assume(check != address(this));
    }

    function _notUsed(
        address check
    ) internal view {
        vm.assume(!_usedAddrs()._contains(check));
    }

    function _notPreCompile(
        address check
    ) internal pure {
        assumeNotPrecompile(check);
        vm.assume(address(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D) != check);
        vm.assume(address(0x4e59b44847b379578588920cA78FbF26c0B4956C) != check);
        vm.assume(address(0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496) != check);
        vm.assume(address(0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f) != check);
        vm.assume(address(0x000000000000000000636F6e736F6c652e6c6f67) != check);
    }

}