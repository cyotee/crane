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
// import { VmSafe } from "forge-std/Vm.sol";
import {StdCheatsSafe} from 
// StdCheats
"forge-std/StdCheats.sol";
// import { Test } from "forge-std/Test.sol";
// import {StdAssertions} from "forge-std/StdAssertions.sol";
// import {StdInvariant} from "forge-std/StdInvariant.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* ------------------------------- Interfaces ------------------------------- */

import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IBatchRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";
import {IBufferRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBufferRouter.sol";
import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
// import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";

/* ---------------------------------- Vault --------------------------------- */

// import { BasicAuthorizerMock } from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
// import { BatchRouter } from "@balancer-labs/v3-vault/contracts/BatchRouter.sol";
// import { BatchRouterMock } from "@balancer-labs/v3-vault/contracts/test/BatchRouterMock.sol";
// import { BufferRouter } from "@balancer-labs/v3-vault/contracts/BufferRouter.sol";
// import { BufferRouterMock } from "@balancer-labs/v3-vault/contracts/test/BufferRouterMock.sol";
// import { CompositeLiquidityRouter } from "@balancer-labs/v3-vault/contracts/CompositeLiquidityRouter.sol";
// import { CompositeLiquidityRouterMock } from "@balancer-labs/v3-vault/contracts/test/CompositeLiquidityRouterMock.sol";
// import { Router } from "@balancer-labs/v3-vault/contracts/Router.sol";
// import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import {WeightedPool8020Factory} from "@balancer-labs/v3-pool-weighted/contracts/WeightedPool8020Factory.sol";
import {ProtocolFeeController} from "@balancer-labs/v3-vault/contracts/ProtocolFeeController.sol";
import {VaultFactory} from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";
import {Vault} from "@balancer-labs/v3-vault/contracts/Vault.sol";
import {VaultExtension} from "@balancer-labs/v3-vault/contracts/VaultExtension.sol";
import {VaultAdmin} from "@balancer-labs/v3-vault/contracts/VaultAdmin.sol";
// import { VaultAdminMock } from "@balancer-labs/v3-vault/contracts/test/VaultAdminMock.sol";
import {VaultFactory} from "@balancer-labs/v3-vault/contracts/VaultFactory.sol";
// import { VaultContractsDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultContractsDeployer.sol";

/* ---------------------------------- Mocks --------------------------------- */

// import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
// import { RateProviderMock } from "@balancer-labs/v3-vault/contracts/test/RateProviderMock.sol";
import {VaultMock} from "@balancer-labs/v3-vault/contracts/test/VaultMock.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "contracts/crane/constants/protocols/dexes/balancer/v3/BalancerV3_CONSTANTS.sol";
import "contracts/crane/constants/protocols/dexes/balancer/v3/BalancerV3_INITCODE.sol";
// import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {Script_Permit2} from "contracts/crane/script/protocols/Script_Permit2.sol";
import {Script_Crane} from "contracts/crane/script/Script_Crane.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {
    BetterBaseContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/solidity-utils/BetterBaseContractsDeployer.sol";
import {
    BetterVaultContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/vault/BetterVaultContractsDeployer.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {Bytecode} from "contracts/crane/utils/Bytecode.sol";
import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {ETHEREUM_MAIN} from "contracts/crane/constants/networks/ETHEREUM_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "contracts/crane/constants/networks/ETHEREUM_SEPOLIA.sol";
// import { IOwnable } from "contracts/crane/interfaces/IOwnable.sol";
import {BalancerV3Authorizer} from "contracts/crane/protocols/dexes/balancer/v3/vault/BalancerV3Authorizer.sol";

// import { BetterTest } from "contracts/crane/test/BetterTest.sol";
import {Script_WETH} from "contracts/crane/script/protocols/Script_WETH.sol";

import {IERC4626RateProvider} from "contracts/crane/interfaces/IERC4626RateProvider.sol";
import {
    ERC4626RateProviderFacetDFPkg
} from "contracts/crane/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol";
import {
    BetterWeightedPoolContractsDeployer
} from "contracts/crane/protocols/dexes/balancer/v3/weighted/BetterWeightedPoolContractsDeployer.sol";

abstract contract Script_BalancerV3 is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,
    Script_WETH,
    Script_Permit2,
    Script_Crane,
    BetterBaseContractsDeployer,
    BetterVaultContractsDeployer,
    BetterWeightedPoolContractsDeployer
{
    using Address for address;
    using stdStorage for StdStorage;

    uint32 constant DEFAULT_PAUSE_WINDOW = 90 days;
    uint32 constant DEFAULT_BUFFER_PERIOD = 30 days;
    uint256 constant DEFAULT_MIN_TRADE_AMOUNT = 1e6;
    uint256 constant DEFAULT_MIN_WRAP_AMOUNT = 1e4;
    bytes32 public constant _HARDCODED_SALT =
        bytes32(0xae0bdc4eeac5e950b67c6819b118761caaf619464ad74a6048c67c03598dc543);
    // address private constant _HARDCODED_VAULT_ADDRESS = address(0xbA133381ef63946fF77A7D009DFcdBdE5c77b92F);

    function builderKey_BalancerV3() public pure returns (string memory) {
        return "balancerV3";
    }

    function run()
        public
        virtual
        override(
            ScriptBase_Crane_Factories,
            ScriptBase_Crane_ERC20,
            ScriptBase_Crane_ERC4626,
            Script_WETH,
            Script_Permit2,
            Script_Crane
        )
    {
        // console.log("Script_BalancerV3.run():: Entering function.");
        super.run();
        // console.log("Script_BalancerV3.run():: Exiting function.");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Builder Functions                           */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------------------------------------------- */
    /*                          IERC4626RateProvider                          */
    /* ---------------------------------------------------------------------- */

    function balV3ERC4626RateProvider(IERC4626 erc4626Vault_)
        public
        virtual
        returns (IERC4626RateProvider erc4626RateProvider_)
    {
        require(address(erc4626Vault_) != address(0), "ERC4626 vault address is zero");
        erc4626RateProvider_ = IERC4626RateProvider(
            diamondFactory().deploy(balV3ERC4626RateProviderFacetDFPkg(), abi.encode(erc4626Vault_))
        );
        declare(builderKey_BalancerV3(), erc4626Vault_.name(), address(erc4626RateProvider_));
        return erc4626RateProvider_;
    }

    /* ---------------------------------------------------------------------- */
    /*                               Authorizer                               */
    /* ---------------------------------------------------------------------- */

    function balV3Authorizer(uint256 chainid, IAuthorizer authorizer_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_AUTHORIZER_INITCODE_HASH, address(authorizer_));
        declare(builderKey_BalancerV3(), "authorizer", address(authorizer_));
        return true;
    }

    function balV3Authorizer(IAuthorizer authorizer_) public virtual returns (bool) {
        balV3Authorizer(block.chainid, authorizer_);
        return true;
    }

    function balV3Authorizer(uint256 chainid) public view returns (IAuthorizer authorizer_) {
        authorizer_ = IAuthorizer(chainInstance(chainid, BALANCER_V3_AUTHORIZER_INITCODE_HASH));
    }

    function balV3Authorizer(bytes memory initArgs) public virtual returns (IAuthorizer authorizer_) {
        if (address(balV3Authorizer(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                authorizer_ = IAuthorizer(ETHEREUM_MAIN.BALANCER_V3_AUTHORIZER);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                authorizer_ = IAuthorizer(ETHEREUM_SEPOLIA.BALANCER_V3_AUTHORIZER);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                if (areTestMocksEnabled() == true) {
                    // authorizer_ = new BasicAuthorizerMock();
                    authorizer_ = IAuthorizer(
                        factory().create2(abi.encodePacked(BALANCER_V3_AUTHORIZER_MOCK_INITCODE, initArgs), "")
                    );
                } else {
                    authorizer_ =
                        IAuthorizer(factory().create2(abi.encodePacked(BALANCER_V3_AUTHORIZER_INITCODE, initArgs), ""));
                }
            } else {
                authorizer_ = new BalancerV3Authorizer(abi.decode(initArgs, (address)));
            }
            balV3Authorizer(authorizer_);
        }
        return balV3Authorizer(block.chainid);
    }

    function balV3Authorizer() public virtual returns (IAuthorizer authorizer_) {
        authorizer_ = balV3Authorizer(abi.encode(owner()));
    }

    /* ---------------------------------------------------------------------- */
    /*                              Vault Factory                             */
    /* ---------------------------------------------------------------------- */

    function balV3VaultFactory(uint256 chainid, VaultFactory vaultFactory_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_VAULT_FACTORY_INITCODE_HASH, address(vaultFactory_));
        declare(builderKey_BalancerV3(), "vaultFactory", address(vaultFactory_));
        return true;
    }

    function balV3VaultFactory(VaultFactory vaultFactory_) public virtual returns (bool) {
        balV3VaultFactory(block.chainid, vaultFactory_);
        return true;
    }

    function balV3VaultFactory(uint256 chainid) public view returns (VaultFactory vaultFactory_) {
        vaultFactory_ = VaultFactory(chainInstance(chainid, BALANCER_V3_VAULT_FACTORY_INITCODE_HASH));
    }

    function balV3VaultFactory(
        IAuthorizer authorizer_,
        uint32 pauseWindowDuration_,
        uint32 bufferPeriodDuration_,
        uint256 minTradeAmount_,
        uint256 minWrapAmount_,
        bytes32 vaultCreationCodeHash_,
        bytes32 vaultExtensionCreationCodeHash_,
        bytes32 vaultAdminCreationCodeHash_
    ) public virtual returns (VaultFactory vaultFactory_) {
        if (address(balV3VaultFactory(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                vaultFactory_ = VaultFactory(ETHEREUM_MAIN.BALANCER_V3_VAULT_FACTORY);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                vaultFactory_ = VaultFactory(ETHEREUM_SEPOLIA.BALANCER_V3_VAULT_FACTORY);
            } else {
                vaultFactory_ = deployVaultFactory(
                    authorizer_,
                    pauseWindowDuration_,
                    bufferPeriodDuration_,
                    minTradeAmount_,
                    minWrapAmount_,
                    vaultCreationCodeHash_,
                    vaultExtensionCreationCodeHash_,
                    vaultAdminCreationCodeHash_
                );
            }
            balV3VaultFactory(vaultFactory_);
        }
        return balV3VaultFactory(block.chainid);
    }

    function balV3VaultFactory(
        IAuthorizer authorizer_,
        bytes32 vaultCreationCodeHash_,
        bytes32 vaultExtensionCreationCodeHash_,
        bytes32 vaultAdminCreationCodeHash_
    ) public virtual returns (VaultFactory vaultFactory_) {
        return balV3VaultFactory(
            // IAuthorizer authorizer_,
            authorizer_,
            // uint32 pauseWindowDuration_,
            DEFAULT_PAUSE_WINDOW,
            // uint32 bufferPeriodDuration_,
            DEFAULT_BUFFER_PERIOD,
            // uint256 minTradeAmount_,
            DEFAULT_MIN_TRADE_AMOUNT,
            // uint256 minWrapAmount_,
            DEFAULT_MIN_WRAP_AMOUNT,
            // bytes32 vaultCreationCodeHash_,
            vaultCreationCodeHash_,
            // bytes32 vaultExtensionCreationCodeHash_,
            vaultExtensionCreationCodeHash_,
            // bytes32 vaultAdminCreationCodeHash_
            vaultAdminCreationCodeHash_
        );
    }

    function balV3VaultFactory(bytes memory initArgs) public virtual returns (VaultFactory vaultFactory_) {
        return balV3VaultFactory(
            // IAuthorizer authorizer_,
            abi.decode(initArgs, (IAuthorizer)),
            // uint32 pauseWindowDuration_,
            DEFAULT_PAUSE_WINDOW,
            // uint32 bufferPeriodDuration_,
            DEFAULT_BUFFER_PERIOD,
            // uint256 minTradeAmount_,
            DEFAULT_MIN_TRADE_AMOUNT,
            // uint256 minWrapAmount_,
            DEFAULT_MIN_WRAP_AMOUNT,
            // bytes32 vaultCreationCodeHash_,
            BALANCER_V3_VAULT_INITCODE_HASH,
            // bytes32 vaultExtensionCreationCodeHash_,
            BALANCER_V3_VAULT_EXTENSION_INITCODE_HASH,
            // bytes32 vaultAdminCreationCodeHash_
            BALANCER_V3_VAULT_ADMIN_INITCODE_HASH
        );
    }

    function balV3VaultFactory() public virtual returns (VaultFactory vaultFactory_) {
        return balV3VaultFactory(abi.encode(balV3Authorizer()));
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IVault                                 */
    /* ---------------------------------------------------------------------- */

    function balancerV3Vault(uint256 chainid, IVault vault_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_VAULT_INITCODE_HASH, address(vault_));
        declare(builderKey_BalancerV3(), "vault", address(vault_));
        return true;
    }

    function balV3Vault(uint256 chainid, IVault vault_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_VAULT_INITCODE_HASH, address(vault_));
        declare(builderKey_BalancerV3(), "vault", address(vault_));
        return true;
    }

    function balancerV3Vault(IVault vault_) public virtual returns (bool) {
        balV3Vault(block.chainid, vault_);
        return true;
    }

    function balV3Vault(IVault vault_) public virtual returns (bool) {
        balV3Vault(block.chainid, vault_);
        return true;
    }

    function balV3Vault(uint256 chainid) public view returns (IVault vault_) {
        vault_ = IVault(chainInstance(chainid, BALANCER_V3_VAULT_INITCODE_HASH));
    }

    function balV3Vault(
        bytes32 salt,
        address targetAddress,
        IProtocolFeeController protocolFeeController,
        uint256 minTradeAmount,
        uint256 minWrapAmount,
        uint256 protocolSwapFeePercentage,
        uint256 protocolYieldFeePercentage
    ) public virtual returns (IVault vault_) {
        if (address(balV3Vault(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                vault_ = IVault(ETHEREUM_MAIN.BALANCER_V3_VAULT);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                vault_ = IVault(ETHEREUM_SEPOLIA.BALANCER_V3_VAULT);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                if (areTestMocksEnabled() == true) {
                    if (isAnyScript() == true) {
                        contextNotSupported(type(VaultMock).name);
                    }
                    vault_ = deployVaultMock(
                        minTradeAmount, minWrapAmount, protocolSwapFeePercentage, protocolYieldFeePercentage
                    );
                } else {
                    balV3VaultFactory()
                        .create(
                            // bytes32 salt,
                            salt,
                            // address targetAddress,
                            targetAddress,
                            // IProtocolFeeController protocolFeeController,
                            protocolFeeController,
                            // bytes calldata vaultCreationCode,
                            type(Vault).creationCode,
                            // bytes calldata vaultExtensionCreationCode,
                            type(VaultExtension).creationCode,
                            // bytes calldata vaultAdminCreationCode
                            type(VaultAdmin).creationCode
                        );
                    vault_ = IVault(balV3VaultFactory().getDeploymentAddress(salt));
                }
            }
            balV3Vault(vault_);
        }
        return balV3Vault(block.chainid);
    }

    function balancerV3Vault() public virtual returns (IVault vault_) {
        return balV3Vault(
            // bytes32 salt,
            _HARDCODED_SALT,
            // address targetAddress,
            Bytecode._create3AddressFromOf(address(balV3VaultFactory()), _HARDCODED_SALT),
            // IProtocolFeeController protocolFeeController,
            balV3ProtocolFeeController(),
            // uint256 minTradeAmount,
            0,
            // uint256 minWrapAmount,
            1,
            // uint256 protocolSwapFeePercentage,
            0,
            // uint256 protocolYieldFeePercentage
            0
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IProtocolFeeController                         */
    /* ---------------------------------------------------------------------- */

    function balV3ProtocolFeeController(uint256 chainid, IProtocolFeeController protocolFeeController_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, BALANCER_V3_PROTOCOL_FEE_CONTROLLER_INITCODE_HASH, address(protocolFeeController_));
        declare(builderKey_BalancerV3(), "protocolFeeController", address(protocolFeeController_));
        return true;
    }

    function balV3ProtocolFeeController(IProtocolFeeController protocolFeeController_) public virtual returns (bool) {
        balV3ProtocolFeeController(block.chainid, protocolFeeController_);
        return true;
    }

    function balV3ProtocolFeeController(uint256 chainid)
        public
        view
        returns (IProtocolFeeController protocolFeeController_)
    {
        protocolFeeController_ =
            IProtocolFeeController(chainInstance(chainid, BALANCER_V3_PROTOCOL_FEE_CONTROLLER_INITCODE_HASH));
    }

    function balV3ProtocolFeeController(bytes32 vaultSalt)
        public
        virtual
        returns (IProtocolFeeController protocolFeeController_)
    {
        if (address(balV3ProtocolFeeController(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                protocolFeeController_ = IProtocolFeeController(ETHEREUM_MAIN.BALANCER_V3_PROTOCOL_FEE_CONTROLLER_2);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                protocolFeeController_ = IProtocolFeeController(ETHEREUM_SEPOLIA.BALANCER_V3_PROTOCOL_FEE_CONTROLLER_2);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                protocolFeeController_ = new ProtocolFeeController(
                    IVault(Bytecode._create3AddressFromOf(address(balV3VaultFactory()), vaultSalt)), 0, 0
                );
            }
            balV3ProtocolFeeController(protocolFeeController_);
        }
        return balV3ProtocolFeeController(block.chainid);
    }

    function balV3ProtocolFeeController() public virtual returns (IProtocolFeeController protocolFeeController_) {
        return balV3ProtocolFeeController(_HARDCODED_SALT);
    }

    /* ---------------------------------------------------------------------- */
    /*                              VaultExplorer                             */
    /* ---------------------------------------------------------------------- */

    function balV3VaultExplorer(uint256 chainid, VaultExplorer vaultExplorer_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_VAULT_EXPLORER_INITCODE_HASH, address(vaultExplorer_));
        declare(builderKey_BalancerV3(), "vaultExplorer", address(vaultExplorer_));
        return true;
    }

    function balV3VaultExplorer(VaultExplorer vaultExplorer_) public virtual returns (bool) {
        balV3VaultExplorer(block.chainid, vaultExplorer_);
        return true;
    }

    function balV3VaultExplorer(uint256 chainid) public view returns (VaultExplorer vaultExplorer_) {
        vaultExplorer_ = VaultExplorer(chainInstance(chainid, BALANCER_V3_VAULT_EXPLORER_INITCODE_HASH));
    }

    function balV3VaultExplorer(bytes memory initArgs) public virtual returns (VaultExplorer vaultExplorer_) {
        if (address(balV3VaultExplorer(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                vaultExplorer_ = VaultExplorer(ETHEREUM_MAIN.BALANCER_V3_VAULT_EXPLORER);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                vaultExplorer_ = deployVaultExplorer(abi.decode(initArgs, (IVault)));
                // vaultExplorer_ =  new VaultExplorer(abi.decode(initArgs, (IVault)));
                // vaultExplorer_ = VaultExplorer(factory().create2(abi.encodePacked(BALANCER_V3_VAULT_EXPLORER_INITCODE, initArgs), ""));
            }
            balV3VaultExplorer(vaultExplorer_);
        }
        return balV3VaultExplorer(block.chainid);
    }

    function balV3VaultExplorer() public virtual returns (VaultExplorer vaultExplorer_) {
        return balV3VaultExplorer(abi.encode(balV3VaultFactory()));
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IRouter                                */
    /* ---------------------------------------------------------------------- */

    function balancerV3Router(uint256 chainid, IRouter router_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_ROUTER_INITCODE_HASH, address(router_));
        declare(builderKey_BalancerV3(), "router", address(router_));
        return true;
    }

    function balancerV3Router(IRouter router_) public virtual returns (bool) {
        balancerV3Router(block.chainid, router_);
        return true;
    }

    function balancerV3Router(uint256 chainid) public view returns (IRouter router_) {
        router_ = IRouter(chainInstance(chainid, BALANCER_V3_ROUTER_INITCODE_HASH));
    }

    function balancerV3Router() public virtual returns (IRouter router_) {
        if (address(balancerV3Router(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                router_ = IRouter(ETHEREUM_MAIN.BALANCER_V3_ROUTER);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                router_ = IRouter(ETHEREUM_SEPOLIA.BALANCER_V3_ROUTER);
            }
            // else
            // if (block.chainid == LOCAL.CHAIN_ID) {
            //     router_ = new Router();
            // }
            balancerV3Router(router_);
        }
        return balancerV3Router(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                              IBatchRouter                              */
    /* ---------------------------------------------------------------------- */

    function balancerV3BatchRouter(uint256 chainid, IBatchRouter batchRouter_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_BATCH_ROUTER_INITCODE_HASH, address(batchRouter_));
        declare(builderKey_BalancerV3(), "batchRouter", address(batchRouter_));
        return true;
    }

    function balancerV3BatchRouter(IBatchRouter batchRouter_) public virtual returns (bool) {
        balancerV3BatchRouter(block.chainid, batchRouter_);
        return true;
    }

    function balancerV3BatchRouter(uint256 chainid) public view returns (IBatchRouter batchRouter_) {
        batchRouter_ = IBatchRouter(chainInstance(chainid, BALANCER_V3_BATCH_ROUTER_INITCODE_HASH));
    }

    function balancerV3BatchRouter() public virtual returns (IBatchRouter batchRouter_) {
        if (address(balancerV3BatchRouter(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                batchRouter_ = IBatchRouter(ETHEREUM_MAIN.BALANCER_V3_BATCH_ROUTER);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                batchRouter_ = IBatchRouter(ETHEREUM_SEPOLIA.BALANCER_V3_BATCH_ROUTER);
            }
            // else
            // if (block.chainid == LOCAL.CHAIN_ID) {
            //     batchRouter_ = new BatchRouter();
            // }
            balancerV3BatchRouter(batchRouter_);
        }
        return balancerV3BatchRouter(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                              IBufferRouter                             */
    /* ---------------------------------------------------------------------- */

    function balancerV3BufferRouter(uint256 chainid, IBufferRouter bufferRouter_) public virtual returns (bool) {
        registerInstance(chainid, BALANCER_V3_BUFFER_ROUTER_INITCODE_HASH, address(bufferRouter_));
        declare(builderKey_BalancerV3(), "bufferRouter", address(bufferRouter_));
        return true;
    }

    function balancerV3BufferRouter(IBufferRouter bufferRouter_) public virtual returns (bool) {
        balancerV3BufferRouter(block.chainid, bufferRouter_);
        return true;
    }

    function balancerV3BufferRouter(uint256 chainid) public view returns (IBufferRouter bufferRouter_) {
        bufferRouter_ = IBufferRouter(chainInstance(chainid, BALANCER_V3_BUFFER_ROUTER_INITCODE_HASH));
    }

    function balancerV3BufferRouter() public virtual returns (IBufferRouter bufferRouter_) {
        if (address(balancerV3BufferRouter(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                bufferRouter_ = IBufferRouter(ETHEREUM_MAIN.BALANCER_V3_BUFFER_ROUTER);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                bufferRouter_ = IBufferRouter(ETHEREUM_SEPOLIA.BALANCER_V3_BUFFER_ROUTER);
            }
            // else
            // if (block.chainid == LOCAL.CHAIN_ID) {
            //     bufferRouter_ = new BufferRouter();
            // }
            balancerV3BufferRouter(bufferRouter_);
        }
        return balancerV3BufferRouter(block.chainid);
    }

    /* -------------------------------------------------------------------------- */
    /*                           WeightedPool8020Factory                          */
    /* -------------------------------------------------------------------------- */

    function balV3WeightedPool8020Factory(uint256 chainid, WeightedPool8020Factory weightedPool8020Factory_)
        public
        virtual
        returns (bool)
    {
        registerInstance(chainid, BALANCER_V3_WEIGHTED_POOL_8020_FACTORY_INITCODE_HASH, address(weightedPool8020Factory_));
        declare(builderKey_BalancerV3(), "weightedPool8020Factory", address(weightedPool8020Factory_));
        return true;
    }

    function balV3WeightedPool8020Factory(WeightedPool8020Factory instance) public returns (bool) {
        return balV3WeightedPool8020Factory(block.chainid, instance);
    }

    function balV3WeightedPool8020Factory(uint256 chainId) public view returns(WeightedPool8020Factory) {
        return WeightedPool8020Factory(chainInstance(chainId, BALANCER_V3_WEIGHTED_POOL_8020_FACTORY_INITCODE_HASH));
    }

    function balV3WeightedPool8020Factory(
        IVault vault,
        uint32 pauseWindowDuration,
        string memory factoryVersion,
        string memory poolVersion
    ) public returns (WeightedPool8020Factory instance) {
        if (address(balV3WeightedPool8020Factory(block.chainid)) == address(0)) {
            instance = deployWeightedPool8020Factory(
                vault,
                pauseWindowDuration,
                factoryVersion,
                poolVersion
            );
            balV3WeightedPool8020Factory(instance);
        }
        return balV3WeightedPool8020Factory(block.chainid);
    }

    function balV3WeightedPool8020Factory() public returns (WeightedPool8020Factory instance) {
        return balV3WeightedPool8020Factory(
            balancerV3Vault(),
            BALANCER_V3_WEIGHTED_POOL_PAUSE_WINDOW_DURATION,
            "Factory v1",
            "8020Pool v1"
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                      ERC4626RateProviderFacetDFPkg                     */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function balV3ERC4626RateProviderFacetDFPkg(
        uint256 chainid,
        ERC4626RateProviderFacetDFPkg erc4626RateProviderFacetDFPkg_
    ) public virtual returns (bool) {
        registerInstance(
            chainid, ERC4626_RATE_PROVIDER_FACET_DFPKG_INITCODE_HASH, address(erc4626RateProviderFacetDFPkg_)
        );
        declare(builderKey_BalancerV3(), "erc4626RateProviderFacetDFPkg", address(erc4626RateProviderFacetDFPkg_));
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balV3ERC4626RateProviderFacetDFPkg(ERC4626RateProviderFacetDFPkg erc4626RateProviderFacetDFPkg_)
        public
        virtual
        returns (bool)
    {
        balV3ERC4626RateProviderFacetDFPkg(block.chainid, erc4626RateProviderFacetDFPkg_);
        return true;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balV3ERC4626RateProviderFacetDFPkg(uint256 chainid)
        public
        view
        returns (ERC4626RateProviderFacetDFPkg erc4626RateProviderFacetDFPkg_)
    {
        erc4626RateProviderFacetDFPkg_ =
            ERC4626RateProviderFacetDFPkg(chainInstance(chainid, ERC4626_RATE_PROVIDER_FACET_DFPKG_INITCODE_HASH));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function balV3ERC4626RateProviderFacetDFPkg()
        public
        virtual
        returns (ERC4626RateProviderFacetDFPkg erc4626RateProviderFacetDFPkg_)
    {
        if (address(balV3ERC4626RateProviderFacetDFPkg(block.chainid)) == address(0)) {
            erc4626RateProviderFacetDFPkg_ = ERC4626RateProviderFacetDFPkg(
                factory()
                    .create3(ERC4626_RATE_PROVIDER_FACET_DFPKG_INITCODE, "", ERC4626_RATE_PROVIDER_FACET_DFPKG_SALT)
            );

            balV3ERC4626RateProviderFacetDFPkg(erc4626RateProviderFacetDFPkg_);
        }
        return balV3ERC4626RateProviderFacetDFPkg(block.chainid);
    }
}
