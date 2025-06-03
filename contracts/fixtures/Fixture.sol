// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// import "forge-std/console.sol";
// import "forge-std/console2.sol";

// import "forge-std/Base.sol";
// import "contracts/crane/utils/Collections.sol";

import {betterconsole as console} from "../utils/vm/foundry/tools/betterconsole.sol";

import {
    AddressSet,
    AddressSetRepo
} from "../utils/collections/sets/AddressSetRepo.sol";
import {
    StringSet,
    StringSetRepo
} from "../utils/collections/sets/StringSetRepo.sol";
import {
    FoundryVM
} from "../utils/vm/foundry/FoundryVM.sol";
import {
    DeclaredAddrs
} from "../utils/vm/foundry/tools/DeclaredAddrs.sol";
import {
    IFixture
} from "../interfaces/IFixture.sol";

/**
 * @title Fixture
 * @author cyotee doge <doge.cyotee>
 * @notice A Fixture encapsulates the addresses and deployment of a protocol into functions.
 * @notice This consolidates and segregates deployment logic.
 * @notice Typical usage to override deployment is to set address.
 * @dev provided to simplify inheritance of dependencies.
 */
abstract contract Fixture
is
FoundryVM,
DeclaredAddrs,
IFixture
{

    using AddressSetRepo for AddressSet;
    using StringSetRepo for StringSet;

    bool internal _testMocksEnabled;

    function areTestMocksEnabled() public view returns (bool) {
        return _testMocksEnabled;
    }

    function disableTestMocks() public {
        _testMocksEnabled = false;
    }

    function enableTestMocks() public {
        _testMocksEnabled = true;
    }

    function initialize()
    public virtual;

    mapping(uint256 chainid => mapping(bytes32 initCodeHash => address target)) _instanceOfChainId; 

    function registerInstance(
        uint256 chainid,
        bytes32 initCodeHash,
        address target
    ) public {
        _instanceOfChainId[chainid][initCodeHash] = target;
    }

    function chainInstance(
        uint256 chainid,
        bytes32 initCodeHash
    ) public view returns (address) {
        return _instanceOfChainId[chainid][initCodeHash];
    }

    string constant DEPLOYMENT_PATH_PREFIX = "deployments/";

    string internal _deploymentPath;

    function deploymentPath() public view returns (string memory) {
        return _deploymentPath;
    }

    function setDeploymentPath(
        string memory path
    ) public {
        _deploymentPath = string.concat(DEPLOYMENT_PATH_PREFIX, path);
    }

    StringSet internal _builderKeys;
    mapping(bytes32 => string json) internal _jsonOfKey;

    function json(string memory builderKey) public view returns (string memory) {
        return _jsonOfKey[keccak256(bytes(builderKey))];
    }

    // TODO DEPRECATE make this a mapping to build JSON of nested values.
    string _deploymentJSON;

    function deploymentJSON() public view returns (string memory) {
        return _deploymentJSON;
    }

    function setDeploymentJSON(
        string memory json_
    ) public {
        _deploymentJSON = json_;
    }

    function declare(
        string memory builderKey,
        string memory label,
        address subject
    ) public {
        declareAddr(subject, label);
        _builderKeys._add(builderKey);
        _jsonOfKey[keccak256(bytes(builderKey))] = vm.serializeAddress(
            builderKey,
            label,
            subject
        );
    }

    function declare(
        string memory label,
        address subject
    ) public {
        declare(
            "all",
            label,
            subject
        );
        // TODO DEPRECATE
        _deploymentJSON = json("all");
    }

    address _deployer;

    function deployer() public view virtual returns (address) {
        return _deployer;
    }

    function setDeployer(
        address deployer_
    ) public {
        declareAddr(deployer_, "deployer");
        _deployer = deployer_;
    }
    
    address _owner;

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function setOwner(
        address owner_
    ) public {
        declareAddr(owner_, "owner");
        _owner = owner_;
    }

}
