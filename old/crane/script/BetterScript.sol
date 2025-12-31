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
import {VmSafe} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {DEPLOYMENTS_PATH} from "@crane/src/constants/Constants.sol";
import {terminal as term} from "contracts/crane/utils/vm/foundry/tools/terminal.sol";
import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {StringSet, StringSetRepo} from "@crane/src/utils/collections/sets/StringSetRepo.sol";

abstract contract BetterScript is CommonBase, ScriptBase, StdChains, StdCheatsSafe, StdUtils, Script {
    using AddressSetRepo for AddressSet;
    using StringSetRepo for StringSet;

    error FunctionNotSupportedInConext(VmSafe.ForgeContext context, string functionSig);

    /**
     * @dev Error thrown when a function is not supported in the current context.
     * @param context The context in which the function is not supported.
     * @param contractName The name of the contract that is not supported.
     */
    error ContractNotSupportedInConext(VmSafe.ForgeContext context, string contractName);

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    // /**
    //  * @dev Modifier to revert if the function is called in a context that is not in the TestGroup.
    //  * @param contractName The name of the contract that is not supported.
    //  */
    // modifier onlyAnyTest(string memory contractName) {
    //     if(!isAnyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.TestGroup, contractName);
    //     }
    //     _;
    // }

    // /**
    //  *
    //  */
    // modifier neverAnyTest(string memory contractName) {
    //     if(isAnyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.TestGroup, contractName);
    //     }
    //     _;
    // }

    function isAnyTest() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.TestGroup);
    }

    // modifier onlyTest(string memory contractName) {
    //     if(!isOnlyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Test, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyTest(string memory contractName) {
    //     if(isOnlyTest()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Test, contractName);
    //     }
    //     _;
    // }

    function isOnlyTest() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.Test);
    }

    // modifier onlyCoverage(string memory contractName) {
    //     if(!isOnlyCoverage()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Coverage, contractName);
    //     }
    //     _;
    // }

    // modifier neverAnyCoverage(string memory contractName) {
    //     if(isOnlyCoverage()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Coverage, contractName);
    //     }
    //     _;
    // }

    function isOnlyCoverage() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.Coverage);
    }

    // modifier onlySnapshot(string memory contractName) {
    //     if(!isOnlySnapshot()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Snapshot, contractName);
    //     }
    //     _;
    // }

    // modifier neverSnapshot(string memory contractName) {
    //     if(isOnlySnapshot()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.Snapshot, contractName);
    //     }
    //     _;
    // }

    function isOnlySnapshot() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.Snapshot);
    }

    // modifier onlyScriptGroup(string memory contractName) {
    //     if(!isAnyScript()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptGroup, contractName);
    //     }
    //     _;
    // }

    // modifier neverAnyScript(string memory contractName) {
    //     if(isAnyScript()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptGroup, contractName);
    //     }
    //     _;
    // }

    function isAnyScript() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptGroup);
    }

    // modifier onlyDryRun(string memory contractName) {
    //     if(!isOnlyDryRun()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptDryRun, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyDryRun(string memory contractName) {
    //     if(isOnlyDryRun()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptDryRun, contractName);
    //     }
    //     _;
    // }

    function isOnlyDryRun() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptDryRun);
    }

    // modifier onlyBroadcast(string memory contractName) {
    //     if(!isOnlyBroadcast()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptBroadcast, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyBroadcast(string memory contractName) {
    //     if(isOnlyBroadcast()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptBroadcast, contractName);
    //     }
    //     _;
    // }

    function isOnlyBroadcast() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptBroadcast);
    }

    // modifier onlyResume(string memory contractName) {
    //     if(!isOnlyResume()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptResume, contractName);
    //     }
    //     _;
    // }

    // modifier neverOnlyResume(string memory contractName) {
    //     if(isOnlyResume()) {
    //         revert NotSupportedInConext(VmSafe.ForgeContext.ScriptResume, contractName);
    //     }
    //     _;
    // }

    function isOnlyResume() public view returns (bool) {
        return vm.isContext(VmSafe.ForgeContext.ScriptResume);
    }

    function contextNotSupported(string memory contractName) public view {
        if (vm.isContext(VmSafe.ForgeContext.TestGroup)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.TestGroup, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.Test)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.Test, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.Coverage)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.Coverage, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.Snapshot)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.Snapshot, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.ScriptGroup)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptGroup, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.ScriptDryRun)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptDryRun, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.ScriptBroadcast)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptBroadcast, contractName);
        } else if (vm.isContext(VmSafe.ForgeContext.ScriptResume)) {
            revert ContractNotSupportedInConext(VmSafe.ForgeContext.ScriptResume, contractName);
        }
    }

    // TODO Change to registered instance.
    address _deployer;

    function deployer() public view virtual returns (address) {
        return _deployer;
    }

    function setDeployer(address deployer_) public {
        declareAddr(deployer_, "deployer");
        _deployer = deployer_;
    }

    address _owner;

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function owner(address owner_) public virtual {
        setOwner(owner_);
    }

    function setOwner(address owner_) public {
        declareAddr(owner_, "owner");
        _owner = owner_;
    }

    function processDeclaredAddrsToJSON() public {
        for (uint256 i = 0; i < _declaredAddrs._length(); i++) {
            setDeploymentJSON(
                vm.serializeAddress("declaredAddrs", vm.getLabel(_declaredAddrs._index(i)), _declaredAddrs._index(i))
            );
        }
    }

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

    mapping(uint256 chainid => mapping(bytes32 initCodeHash => address target)) _instanceOfChainId;

    function registerInstance(uint256 chainid, bytes32 initCodeHash, address target) public {
        _instanceOfChainId[chainid][initCodeHash] = target;
    }

    function chainInstance(uint256 chainid, bytes32 initCodeHash) public view returns (address) {
        return _instanceOfChainId[chainid][initCodeHash];
    }

    string constant DEPLOYMENT_PATH_PREFIX = "deployments/";

    string internal _deploymentPath;

    function deploymentPath() public view returns (string memory) {
        return _deploymentPath;
    }

    function setDeploymentPath(string memory path) public {
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

    function setDeploymentJSON(string memory json_) public {
        _deploymentJSON = json_;
    }

    function declare(string memory builderKey, string memory label, address subject) public {
        declareAddr(subject, label);
        _builderKeys._add(builderKey);
        _jsonOfKey[keccak256(bytes(builderKey))] = vm.serializeAddress(builderKey, label, subject);
    }

    function declare(string memory label, address subject) public {
        declare("all", label, subject);
        // TODO DEPRECATE
        _deploymentJSON = json("all");
    }

    function loadDeployments(string memory _deploymentsPath) public view virtual returns (string memory json_) {
        string memory deploymentsPath = string.concat(DEPLOYMENTS_PATH, _deploymentsPath);
        return vm.readFile(deploymentsPath);
    }

    function loadAddress(string memory _deploymentsPath, string memory key) public virtual returns (address) {
        return parseJsonAddress(loadDeployments(_deploymentsPath), key);
    }

    function parseJsonAddress(string memory _json, string memory key) public virtual returns (address addr_) {
        require(vm.keyExistsJson(_json, string.concat("$.", key)), string.concat("key: ", key, " not found in json"));
        addr_ = vm.parseJsonAddress(_json, string.concat("$.", key));
        vm.label(addr_, key);
        return addr_;
    }

    function writeDeploymentJSON() public {
        term.mkDir(term.dirName(deploymentPath()));
        term.touch(deploymentPath());
        vm.writeJson(deploymentJSON(), deploymentPath());
    }

    function writeDeploymentJSON(string memory builderKey) public {
        term.mkDir(term.dirName(deploymentPath()));
        term.touch(deploymentPath());
        vm.writeJson(json(builderKey), deploymentPath());
    }

    using AddressSetRepo for AddressSet;

    AddressSet internal _declaredAddrs;

    // TODO Add multi-chain support.
    // mapping(uint256 chainId => mapping(bytes32 label => address subject)) internal _declaredAddrsOfChain;

    function declaredAddrs() public view returns (address[] memory) {
        return _declaredAddrs._values();
    }

    function isDeclared(address subject) public view returns (bool) {
        return _declaredAddrs._contains(subject);
    }

    function declareAddr(address dec) public virtual returns (bool) {
        _declaredAddrs._add(dec);
        return true;
    }

    function declareAddr(address dec, string memory label) public virtual returns (bool) {
        declareAddr(dec);
        vm.label(dec, label);
        return true;
    }
}
