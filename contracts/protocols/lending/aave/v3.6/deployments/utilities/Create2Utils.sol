// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IBattleChainDeployer} from "@battlechain-contracts/interface/IBattleChainDeployer.sol";

/// @notice CREATE2 helpers for Aave V3 batched deploys (Safe Singleton–compatible factory).
/// @dev Path A: factory at CREATE2_FACTORY. Path B: real deploy via BC Deployer or CREATE — no `vm.etch`.
library Create2Utils {
    // https://github.com/safe-global/safe-singleton-factory
    address public constant CREATE2_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;

    /// @dev Bootstrap `60458060093d393df3` (copy 0x45-byte runtime) + official Safe Singleton runtime.
    bytes internal constant SAFE_SINGLETON_FACTORY_INITCODE =
        hex"60458060093d393df37fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3";

    /// @dev Same salt scheme as V4 Create2Utils Path B.
    bytes32 internal constant PATH_B_FACTORY_SALT =
        hex"0000000000000000000000000000000000000000006372616e652d616176652d";

    bytes32 internal constant FACTORY_TSLOT = keccak256("crane.aave.create2.factory.tstore");

    address internal constant BC_DEPLOYER = 0x0f75289c6b883b885A1fDF9BCCABE1bbFB094077;

    function ensureCreate2Factory() internal returns (address factory) {
        if (isContractDeployed(CREATE2_FACTORY)) {
            _tstoreFactory(CREATE2_FACTORY);
            return CREATE2_FACTORY;
        }

        if (isContractDeployed(BC_DEPLOYER)) {
            address pathB = predictedPathBFactory(BC_DEPLOYER);
            if (isContractDeployed(pathB)) {
                _tstoreFactory(pathB);
                return pathB;
            }
            factory = IBattleChainDeployer(BC_DEPLOYER).deployCreate2(PATH_B_FACTORY_SALT, SAFE_SINGLETON_FACTORY_INITCODE);
            require(isContractDeployed(factory), "PATH_B_FACTORY_DEPLOY_FAILED");
            _tstoreFactory(factory);
            return factory;
        }

        factory = _tloadFactory();
        if (factory != address(0) && isContractDeployed(factory)) {
            return factory;
        }
        factory = _create(SAFE_SINGLETON_FACTORY_INITCODE);
        require(factory != address(0) && isContractDeployed(factory), "PATH_B_FACTORY_DEPLOY_FAILED");
        _tstoreFactory(factory);
        return factory;
    }

    function getFactory() internal view returns (address factory) {
        if (isContractDeployed(CREATE2_FACTORY)) return CREATE2_FACTORY;
        address pathB = predictedPathBFactory(BC_DEPLOYER);
        if (isContractDeployed(pathB)) return pathB;
        factory = _tloadFactory();
        require(factory != address(0) && isContractDeployed(factory), "MISSING_CREATE2_FACTORY");
        return factory;
    }

    function predictedPathBFactory(address deployer) internal pure returns (address) {
        bytes32 guardedSalt = keccak256(abi.encode(PATH_B_FACTORY_SALT));
        return addressFromLast20Bytes(
            keccak256(abi.encodePacked(bytes1(0xff), deployer, guardedSalt, keccak256(SAFE_SINGLETON_FACTORY_INITCODE)))
        );
    }

    function _create2Deploy(bytes32 salt, bytes memory bytecode) internal returns (address) {
        address factory = ensureCreate2Factory();
        address computed = computeCreate2Address(factory, salt, bytecode);

        if (isContractDeployed(computed)) {
            return computed;
        } else {
            bytes memory creationBytecode = abi.encodePacked(salt, bytecode);
            (bool success, bytes memory returnData) = factory.call(creationBytecode);
            require(success, "failure at create2 deployment");
            // forge-lint: disable-next-line(unsafe-typecast)
            address deployedAt = address(uint160(bytes20(returnData)));
            require(deployedAt == computed, "failure at create2 address derivation");
            return deployedAt;
        }
    }

    function isContractDeployed(address _addr) internal view returns (bool isContract) {
        return (_addr.code.length > 0);
    }

    function computeCreate2Address(address factory, bytes32 salt, bytes memory bytecode)
        internal
        pure
        returns (address)
    {
        return addressFromLast20Bytes(
            keccak256(abi.encodePacked(bytes1(0xff), factory, salt, keccak256(abi.encodePacked(bytecode))))
        );
    }

    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash) internal view returns (address) {
        return addressFromLast20Bytes(keccak256(abi.encodePacked(bytes1(0xff), getFactory(), salt, initcodeHash)));
    }

    function computeCreate2Address(bytes32 salt, bytes memory bytecode) internal view returns (address) {
        return computeCreate2Address(salt, keccak256(abi.encodePacked(bytecode)));
    }

    function addressFromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function _create(bytes memory initCode) private returns (address addr) {
        assembly {
            addr := create(0, add(initCode, 0x20), mload(initCode))
        }
    }

    function _tstoreFactory(address factory) private {
        bytes32 slot = FACTORY_TSLOT;
        assembly {
            tstore(slot, factory)
        }
    }

    function _tloadFactory() private view returns (address factory) {
        bytes32 slot = FACTORY_TSLOT;
        assembly {
            factory := tload(slot)
        }
    }
}
