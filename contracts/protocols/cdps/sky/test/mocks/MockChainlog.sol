// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title MockChainlog
/// @notice A mock implementation of the MakerDAO Chainlog for local testing
/// @dev Allows tests to register and lookup contract addresses by bytes32 keys
contract MockChainlog {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "MockChainlog/not-authorized");
        _;
    }

    // --- Data ---
    mapping(bytes32 => address) private _addresses;
    bytes32[] private _keys;
    mapping(bytes32 => uint256) private _keyIndex;

    string public version;
    string public sha256sum;
    string public ipfs;

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event UpdateAddress(bytes32 indexed key, address addr);
    event RemoveAddress(bytes32 indexed key);
    event UpdateVersion(string version);
    event UpdateSha256sum(string sha256sum);
    event UpdateIPFS(string ipfs);

    // --- Init ---
    constructor() {
        wards[msg.sender] = 1;
        version = "1.0.0";
        emit Rely(msg.sender);
    }

    // --- Address Management ---

    /// @notice Set an address for a given key
    /// @param key The bytes32 key (e.g., "MCD_VAT", "MCD_DAI")
    /// @param addr The contract address to associate with the key
    function setAddress(bytes32 key, address addr) external auth {
        if (_addresses[key] == address(0) && addr != address(0)) {
            // New key, add to list
            _keyIndex[key] = _keys.length;
            _keys.push(key);
        } else if (_addresses[key] != address(0) && addr == address(0)) {
            // Removing address - remove from list
            _removeKey(key);
        }
        _addresses[key] = addr;
        emit UpdateAddress(key, addr);
    }

    /// @notice Remove an address mapping
    /// @param key The bytes32 key to remove
    function removeAddress(bytes32 key) external auth {
        require(_addresses[key] != address(0), "MockChainlog/key-not-found");
        _removeKey(key);
        delete _addresses[key];
        emit RemoveAddress(key);
    }

    /// @notice Get the address for a given key
    /// @param key The bytes32 key to lookup
    /// @return The address associated with the key
    function getAddress(bytes32 key) external view returns (address) {
        return _addresses[key];
    }

    /// @notice Check if a key exists
    /// @param key The bytes32 key to check
    /// @return True if the key has an associated address
    function hasAddress(bytes32 key) external view returns (bool) {
        return _addresses[key] != address(0);
    }

    /// @notice Get all registered keys
    /// @return Array of all registered keys
    function keys() external view returns (bytes32[] memory) {
        return _keys;
    }

    /// @notice Get the count of registered keys
    /// @return The number of registered keys
    function count() external view returns (uint256) {
        return _keys.length;
    }

    /// @notice Get a key at a specific index
    /// @param index The index to lookup
    /// @return The key at that index
    function keyAt(uint256 index) external view returns (bytes32) {
        require(index < _keys.length, "MockChainlog/index-out-of-bounds");
        return _keys[index];
    }

    // --- Metadata ---

    function setVersion(string calldata _version) external auth {
        version = _version;
        emit UpdateVersion(_version);
    }

    function setSha256sum(string calldata _sha256sum) external auth {
        sha256sum = _sha256sum;
        emit UpdateSha256sum(_sha256sum);
    }

    function setIPFS(string calldata _ipfs) external auth {
        ipfs = _ipfs;
        emit UpdateIPFS(_ipfs);
    }

    // --- Internal ---

    function _removeKey(bytes32 key) internal {
        uint256 index = _keyIndex[key];
        uint256 lastIndex = _keys.length - 1;

        if (index != lastIndex) {
            bytes32 lastKey = _keys[lastIndex];
            _keys[index] = lastKey;
            _keyIndex[lastKey] = index;
        }

        _keys.pop();
        delete _keyIndex[key];
    }
}
