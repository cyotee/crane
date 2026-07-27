// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.20;

import {
    TransparentUpgradeableProxy
} from "@crane/contracts/external/openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {IBattleChainDeployer} from "@battlechain-contracts/interface/IBattleChainDeployer.sol";

/// @title Create2Utils Library
/// @author Aave Labs (+ Crane BC Path B)
/// @notice Deterministic deployment helpers using a Safe Singleton–compatible CREATE2 factory.
/// @dev Path A: official Safe Singleton Factory already live at CREATE2_FACTORY_CANONICAL.
///      Path B: deploy the same factory *runtime* via BattleChainDeployer/CreateX CREATE2 (or plain
///      CREATE fallback in a single transaction). Never uses `vm.etch`.
library Create2Utils {
    // https://github.com/safe-global/safe-singleton-factory
    address public constant CREATE2_FACTORY_CANONICAL = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;

    /// @dev Alias retained for callers that read `CREATE2_FACTORY` as the Path A address.
    address public constant CREATE2_FACTORY = CREATE2_FACTORY_CANONICAL;

    /// @dev Official Safe Singleton Factory runtime (69 bytes / 0x45).
    bytes internal constant SAFE_SINGLETON_FACTORY_RUNTIME =
        hex"7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3";

    /// @dev Full initcode: 9-byte bootstrap (`60458060093d393df3` = copy 0x45 bytes from offset 9) + runtime.
    bytes internal constant SAFE_SINGLETON_FACTORY_INITCODE =
        hex"60458060093d393df37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3";

    /// @dev CreateX-compatible salt: first 20 bytes zero, byte20 = 0x00 (permissionless),
    ///      trailing entropy = "crane-aave-" so guardedSalt = keccak256(abi.encode(salt)).
    bytes32 internal constant PATH_B_FACTORY_SALT =
        hex"0000000000000000000000000000000000000000006372616e652d616176652d";

    /// @dev Transient slot for factory address within a multi-step deploy transaction (CREATE fallback).
    bytes32 internal constant FACTORY_TSLOT = keccak256("crane.aave.create2.factory.tstore");

    /// @dev BattleChain testnet BattleChainDeployer (CreateX-based). Used for Path B on BC.
    address internal constant BC_DEPLOYER = 0x0f75289c6b883b885A1fDF9BCCABE1bbFB094077;

    error MissingCreate2Factory();
    error Create2AddressDerivationFailure();
    error FailedCreate2FactoryCall();
    error ContractAlreadyDeployed();
    error PathBFactoryDeployFailed();

    /// @notice Resolve the CREATE2 factory: Path A if code present, else Path B if deployed, else tstore.
    function getFactory() internal view returns (address factory) {
        if (isContractDeployed(CREATE2_FACTORY_CANONICAL)) {
            return CREATE2_FACTORY_CANONICAL;
        }
        address pathB = predictedPathBFactory(BC_DEPLOYER);
        if (isContractDeployed(pathB)) {
            return pathB;
        }
        factory = _tloadFactory();
        if (factory != address(0) && isContractDeployed(factory)) {
            return factory;
        }
        revert MissingCreate2Factory();
    }

    /// @notice Path A if present; else deploy Path B via BC Deployer CREATE2 (or CREATE fallback).
    /// @dev Real bytecode only — no Foundry cheatcodes.
    function ensureCreate2Factory() internal returns (address factory) {
        if (isContractDeployed(CREATE2_FACTORY_CANONICAL)) {
            _tstoreFactory(CREATE2_FACTORY_CANONICAL);
            return CREATE2_FACTORY_CANONICAL;
        }

        if (isContractDeployed(BC_DEPLOYER)) {
            address pathB = predictedPathBFactory(BC_DEPLOYER);
            if (isContractDeployed(pathB)) {
                _tstoreFactory(pathB);
                return pathB;
            }
            factory = IBattleChainDeployer(BC_DEPLOYER).deployCreate2(PATH_B_FACTORY_SALT, SAFE_SINGLETON_FACTORY_INITCODE);
            if (!isContractDeployed(factory)) revert PathBFactoryDeployFailed();
            _tstoreFactory(factory);
            return factory;
        }

        // Hermetic / Anvil without BC Deployer: plain CREATE (same tx; tstore for follow-ups).
        factory = _tloadFactory();
        if (factory != address(0) && isContractDeployed(factory)) {
            return factory;
        }
        factory = _create(SAFE_SINGLETON_FACTORY_INITCODE);
        if (factory == address(0) || !isContractDeployed(factory)) revert PathBFactoryDeployFailed();
        _tstoreFactory(factory);
        return factory;
    }

    /// @notice Predicted Path B factory address when deployed via `deployer` with PATH_B_FACTORY_SALT.
    function predictedPathBFactory(address deployer) internal pure returns (address) {
        bytes32 guardedSalt = keccak256(abi.encode(PATH_B_FACTORY_SALT));
        return computeCreate2AddressWithDeployer(guardedSalt, keccak256(SAFE_SINGLETON_FACTORY_INITCODE), deployer);
    }

    /// @notice Deploys a contract via CREATE2 using the resolved factory.
    function create2Deploy(bytes32 salt, bytes memory bytecode) internal returns (address) {
        address factory = ensureCreate2Factory();
        address computed = computeCreate2Address(salt, keccak256(bytecode), factory);
        require(!isContractDeployed(computed), ContractAlreadyDeployed());
        bytes memory creationBytecode = abi.encodePacked(salt, bytecode);
        (bool success, bytes memory returnData) = factory.call(creationBytecode);
        require(success, FailedCreate2FactoryCall());
        address deployedAt = address(uint160(bytes20(returnData)));
        require(deployedAt == computed, Create2AddressDerivationFailure());
        return deployedAt;
    }

    /// @notice Idempotent CREATE2 deploy: returns existing address if code present.
    function create2DeployOrGet(bytes32 salt, bytes memory bytecode) internal returns (address) {
        address factory = ensureCreate2Factory();
        address computed = computeCreate2Address(salt, keccak256(bytecode), factory);
        if (isContractDeployed(computed)) return computed;
        return create2Deploy(salt, bytecode);
    }

    /// @notice Deploys a TransparentUpgradeableProxy via CREATE2.
    function proxify(bytes32 salt, address logic, address initialOwner, bytes memory data) internal returns (address) {
        return create2Deploy(
            salt,
            abi.encodePacked(type(TransparentUpgradeableProxy).creationCode, abi.encode(logic, initialOwner, data))
        );
    }

    function isContractDeployed(address _addr) internal view returns (bool isContract) {
        return (_addr.code.length > 0);
    }

    /// @notice CREATE2 address assuming Path A canonical factory (pure; used by callers that stay pure).
    /// @dev For Path B deploys use the 3-arg overload with `ensureCreate2Factory()` / `getFactory()`.
    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash) internal pure returns (address) {
        return computeCreate2Address(salt, initcodeHash, CREATE2_FACTORY_CANONICAL);
    }

    function computeCreate2Address(bytes32 salt, bytes memory bytecode) internal pure returns (address) {
        return computeCreate2Address(salt, keccak256(bytecode), CREATE2_FACTORY_CANONICAL);
    }

    /// @notice CREATE2 address for an explicit factory (Path A or Path B).
    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash, address factory)
        internal
        pure
        returns (address)
    {
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xff), factory, salt, initcodeHash)));
    }

    function computeCreate2AddressWithDeployer(bytes32 salt, bytes32 initcodeHash, address deployer)
        internal
        pure
        returns (address)
    {
        return computeCreate2Address(salt, initcodeHash, deployer);
    }

    function addressFromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function _create(bytes memory initCode) private returns (address addr) {
        assembly ("memory-safe") {
            addr := create(0, add(initCode, 0x20), mload(initCode))
        }
    }

    function _tstoreFactory(address factory) private {
        bytes32 slot = FACTORY_TSLOT;
        assembly ("memory-safe") {
            tstore(slot, factory)
        }
    }

    function _tloadFactory() private view returns (address factory) {
        bytes32 slot = FACTORY_TSLOT;
        assembly ("memory-safe") {
            factory := tload(slot)
        }
    }
}
