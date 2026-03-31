// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IApprovedMessageSenderRegistry} from "@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol";
import {ITokenTransferRelayer} from "@crane/contracts/interfaces/ITokenTransferRelayer.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {ICrossDomainMessenger} from "@crane/contracts/interfaces/protocols/l2s/superchain/ICrossDomainMessenger.sol";
import {IStandardBridge} from "@crane/contracts/interfaces/protocols/l2s/superchain/IStandardBridge.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";

import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";
import {BASE_MAIN} from "@crane/contracts/constants/networks/BASE_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "@crane/contracts/constants/networks/ETHEREUM_SEPOLIA.sol";
import {BASE_SEPOLIA} from "@crane/contracts/constants/networks/BASE_SEPOLIA.sol";

import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ERC20PermitDFPkg, IERC20PermitDFPkg} from "@crane/contracts/tokens/ERC20/ERC20PermitDFPkg.sol";
import {ERC20Facet} from "@crane/contracts/tokens/ERC20/ERC20Facet.sol";
import {ERC2612Facet} from "@crane/contracts/tokens/ERC2612/ERC2612Facet.sol";
import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {ApprovedMessageSenderRegistryFactoryService} from "@crane/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFactoryService.sol";
import {TokenTransferRelayerFactoryService} from "@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerFactoryService.sol";
import {SuperchainSenderNonceRepo} from "@crane/contracts/protocols/l2s/superchain/senders/SuperchainSenderNonceRepo.sol";
import {SuperchainSenderNonceTarget} from "@crane/contracts/protocols/l2s/superchain/senders/SuperchainSenderNonceTarget.sol";

interface IOptimismMintableERC20Factory {
    function createOptimismMintableERC20(
        address remoteToken,
        string memory name,
        string memory symbol
    ) external returns (address);
}

interface IOptimismMintableERC20 is IERC20, IERC20Metadata {
    function remoteToken() external view returns (address);
    function bridge() external view returns (address);
}

interface ITestVaultDepositProcessor {
    function receiveDeposit(address beneficiary, uint256 amount) external;
}

contract TestERC4626Vault is IERC20Events {
    IERC20 public immutable assetToken;

    uint256 public totalAssets;
    uint256 public totalSupply;

    mapping(address => uint256) internal _shareBalanceOf;

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    constructor(IERC20 assetToken_) {
        assetToken = assetToken_;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _shareBalanceOf[account];
    }

    function deposit(uint256 assets, address owner) external returns (uint256 shares) {
        shares = assets;
        totalAssets += assets;
        totalSupply += shares;
        _shareBalanceOf[owner] += shares;
        assetToken.transferFrom(msg.sender, address(this), assets);
        emit Deposit(msg.sender, owner, assets, shares);
        emit Transfer(address(0), owner, shares);
    }
}

contract TestVaultDepositProcessor {
    IERC20 public immutable token;
    TestERC4626Vault public immutable vault;

    event DepositProcessed(address indexed caller, address indexed beneficiary, uint256 amount);

    constructor(IERC20 token_, TestERC4626Vault vault_) {
        token = token_;
        vault = vault_;
    }

    function receiveDeposit(address beneficiary, uint256 amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(vault), amount);
        vault.deposit(amount, beneficiary);
        emit DepositProcessed(msg.sender, beneficiary, amount);
    }
}

contract TestL1VaultSender is SuperchainSenderNonceTarget {
    uint256 public immutable targetChainId;

    IStandardBridge public immutable bridge;
    ICrossDomainMessenger public immutable messenger;

    constructor(IStandardBridge bridge_, ICrossDomainMessenger messenger_, uint256 targetChainId_) {
        bridge = bridge_;
        messenger = messenger_;
        targetChainId = targetChainId_;
    }

    function bridgeToVault(
        IERC20 l1Token,
        address l2Token,
        address l2Relayer,
        address l2Processor,
        address beneficiary,
        uint256 amount,
        uint32 bridgeMinGasLimit,
        uint32 processorMinGasLimit
    ) external {
        uint256 senderNonce = SuperchainSenderNonceRepo._useNonce(address(this), targetChainId);
        l1Token.transferFrom(msg.sender, address(this), amount);
        l1Token.approve(address(bridge), amount);

        bridge.bridgeERC20To(address(l1Token), l2Token, l2Relayer, amount, bridgeMinGasLimit, bytes(""));

        bytes memory processorData = abi.encodeCall(ITestVaultDepositProcessor.receiveDeposit, (beneficiary, amount));
        bytes memory relayData = abi.encodeCall(
            ITokenTransferRelayer.relayTokenTransfer,
            (l2Processor, IERC20(l2Token), amount, senderNonce, false, false, processorData)
        );

        messenger.sendMessage(l2Relayer, relayData, processorMinGasLimit);
    }
}

abstract contract SuperchainPackageTestBase is Test {
    uint32 internal constant _BRIDGE_MIN_GAS_LIMIT = 250_000;
    uint32 internal constant _PROCESSOR_MIN_GAS_LIMIT = 500_000;

    uint160 internal constant _L1_TO_L2_ALIAS_OFFSET = uint160(0x1111000000000000000000000000000000001111);

    bytes32 internal constant _RELAYED_MESSAGE_TOPIC0 = keccak256("RelayedMessage(bytes32)");
    bytes32 internal constant _FAILED_RELAYED_MESSAGE_TOPIC0 = keccak256("FailedRelayedMessage(bytes32)");
    bytes32 internal constant _TOKEN_TRANSFER_RELAYED_TOPIC0 =
        keccak256("TokenTransferRelayed(address,address,address,uint256,uint256,bytes)");
    bytes32 internal constant _VAULT_DEPOSIT_TOPIC0 = keccak256("Deposit(address,address,uint256,uint256)");

    uint256 internal _l1Fork;
    uint256 internal _l2Fork;

    address internal _alice = makeAddr("alice");
    address internal _beneficiary = makeAddr("beneficiary");

    ICreate3FactoryProxy internal _l1Create3Factory;
    IDiamondPackageCallBackFactory internal _l1DiamondFactory;
    ICreate3FactoryProxy internal _l2Create3Factory;
    IDiamondPackageCallBackFactory internal _l2DiamondFactory;

    IERC20 internal _l1Token;
    IOptimismMintableERC20 internal _l2Token;
    TestERC4626Vault internal _vault;
    TestVaultDepositProcessor internal _processor;
    IApprovedMessageSenderRegistry internal _registry;
    ITokenTransferRelayer internal _relayer;
    TestL1VaultSender internal _l1Sender;

    function _l1RpcAlias() internal pure virtual returns (string memory);
    function _l2RpcAlias() internal pure virtual returns (string memory);
    function _l1ForkBlock() internal pure virtual returns (uint256);
    function _l2ForkBlock() internal pure virtual returns (uint256);
    function _l1CrossDomainMessenger() internal pure virtual returns (address);
    function _l1StandardBridge() internal pure virtual returns (address);
    function _l2CrossDomainMessenger() internal pure virtual returns (address);
    function _l2StandardBridge() internal pure virtual returns (address);
    function _l2MintableFactory() internal pure virtual returns (address);
    function _permit2() internal pure virtual returns (address);
    function _l2ChainId() internal pure virtual returns (uint256);

    function setUp() public virtual {
        _l1Fork = vm.createFork(_l1RpcAlias(), _l1ForkBlock());
        _l2Fork = vm.createFork(_l2RpcAlias(), _l2ForkBlock());

        _setUpL1();
        _setUpL2();
    }

    function _setUpL1() internal {
        vm.selectFork(_l1Fork);

        (_l1Create3Factory, _l1DiamondFactory) = InitDevService.initEnv(address(this));
        _l1Token = _deployL1TokenPackage();
        _l1Sender = new TestL1VaultSender(_l1Bridge(), _l1Messenger(), _l2ChainId());

        vm.label(address(_l1Token), "L1Token");
        vm.label(address(_l1Sender), "L1VaultSender");
    }

    function _setUpL2() internal {
        vm.selectFork(_l2Fork);

        (_l2Create3Factory, _l2DiamondFactory) = InitDevService.initEnv(address(this));
        _l2Token = IOptimismMintableERC20(
            IOptimismMintableERC20Factory(_l2MintableFactory()).createOptimismMintableERC20(
                address(_l1Token), "Test Token L2", "TST-L2"
            )
        );

        _vault = new TestERC4626Vault(IERC20(address(_l2Token)));
        _processor = new TestVaultDepositProcessor(IERC20(address(_l2Token)), _vault);
        _registry = _deployRegistryPackage();
        _relayer = _deployRelayerPackage();

        _registry.approveSender(address(_processor), address(_l1Sender));
    }

    function _deployL1TokenPackage() internal returns (IERC20 token) {
        IFacet erc20Facet = _l1Create3Factory.deployFacet(
            type(ERC20Facet).creationCode, keccak256(abi.encode(type(ERC20Facet).name))
        );
        IFacet erc2612Facet = _l1Create3Factory.deployFacet(
            type(ERC2612Facet).creationCode, keccak256(abi.encode(type(ERC2612Facet).name))
        );
        IFacet erc5267Facet = _l1Create3Factory.deployFacet(
            type(ERC5267Facet).creationCode, keccak256(abi.encode(type(ERC5267Facet).name))
        );

        IERC20PermitDFPkg.PkgInit memory pkgInit = IERC20PermitDFPkg.PkgInit({
            erc20Facet: erc20Facet,
            erc5267Facet: erc5267Facet,
            erc2612Facet: erc2612Facet
        });

        ERC20PermitDFPkg dfpkg = ERC20PermitDFPkg(
            address(
                _l1Create3Factory.deployPackageWithArgs(
                    type(ERC20PermitDFPkg).creationCode,
                    abi.encode(pkgInit),
                    keccak256(abi.encode(type(ERC20PermitDFPkg).name, pkgInit))
                )
            )
        );

        IERC20PermitDFPkg.PkgArgs memory pkgArgs = IERC20PermitDFPkg.PkgArgs({
            name: "Test Token",
            symbol: "TST",
            decimals: 18,
            totalSupply: 1_000e18,
            recipient: _alice,
            optionalSalt: bytes32(0)
        });

        token = IERC20(_l1DiamondFactory.deploy(IDiamondFactoryPackage(address(dfpkg)), abi.encode(pkgArgs)));
    }

    function _deployRegistryPackage() internal returns (IApprovedMessageSenderRegistry registry) {
        IFacet registryFacet =
            ApprovedMessageSenderRegistryFactoryService.deployApprovedMessageSenderRegistryFacet(_l2Create3Factory);
        IFacet ownableFacet = IFacetRegistry(address(_l2Create3Factory)).canonicalFacet(type(IMultiStepOwnable).interfaceId);
        IFacet operableFacet = IFacetRegistry(address(_l2Create3Factory)).canonicalFacet(type(IOperable).interfaceId);

        registry = ApprovedMessageSenderRegistryFactoryService.deployApprovedMessageSenderRegistry(
            _l2DiamondFactory,
            ApprovedMessageSenderRegistryFactoryService.deployApprovedMessageSenderRegistryDFPkg(
                _l2Create3Factory,
                ownableFacet,
                operableFacet,
                registryFacet
            ),
            address(this)
        );
    }

    function _deployRelayerPackage() internal returns (ITokenTransferRelayer relayer) {
        relayer = TokenTransferRelayerFactoryService.deployTokenTransferRelayer(
            _l2DiamondFactory,
            TokenTransferRelayerFactoryService.deployTokenTransferRelayerDFPkg(
                _l2Create3Factory,
                IFacetRegistry(address(_l2Create3Factory)).canonicalFacet(type(IMultiStepOwnable).interfaceId),
                TokenTransferRelayerFactoryService.deployTokenTransferRelayerFacet(_l2Create3Factory),
                IPermit2(_permit2())
            ),
            address(this),
            _registry
        );
    }

    function _l1Messenger() internal view returns (ICrossDomainMessenger) {
        return ICrossDomainMessenger(_l1CrossDomainMessenger());
    }

    function _l2Messenger() internal view returns (ICrossDomainMessenger) {
        return ICrossDomainMessenger(_l2CrossDomainMessenger());
    }

    function _l1Bridge() internal view returns (IStandardBridge) {
        return IStandardBridge(payable(_l1StandardBridge()));
    }

    function _computeAlias(address l1Address) internal pure returns (address) {
        return address(uint160(l1Address) + _L1_TO_L2_ALIAS_OFFSET);
    }

    function _encodeVersionedNonce(uint240 nonce, uint16 version) internal pure returns (uint256 encodedNonce) {
        encodedNonce = (uint256(version) << 240) | uint256(nonce);
    }

    function _decodeVersionedNonce(uint256 encodedNonce) internal pure returns (uint240 nonce, uint16 version) {
        nonce = uint240(encodedNonce);
        version = uint16(encodedNonce >> 240);
    }

    function _incrementVersionedNonce(uint256 encodedNonce) internal pure returns (uint256) {
        (uint240 nonce, uint16 version) = _decodeVersionedNonce(encodedNonce);
        return _encodeVersionedNonce(nonce + 1, version);
    }

    function _hashCrossDomainMessageV1(
        uint256 nonce,
        address sender,
        address target,
        uint256 value,
        uint256 gasLimit,
        bytes memory data
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodeWithSignature(
                "relayMessage(uint256,address,address,uint256,uint256,bytes)",
                nonce,
                sender,
                target,
                value,
                gasLimit,
                data
            )
        );
    }

    function _buildBridgeFinalizeMessage(address from, uint256 amount) internal view returns (bytes memory) {
        return abi.encodeCall(
            IStandardBridge.finalizeBridgeERC20,
            (address(_l2Token), address(_l1Token), from, address(_relayer), amount, bytes(""))
        );
    }

    function _buildProcessorRelayMessage(address beneficiary, uint256 amount, uint256 senderNonce)
        internal
        view
        returns (bytes memory)
    {
        bytes memory processorData = abi.encodeCall(ITestVaultDepositProcessor.receiveDeposit, (beneficiary, amount));
        return abi.encodeCall(
            ITokenTransferRelayer.relayTokenTransfer,
            (address(_processor), IERC20(address(_l2Token)), amount, senderNonce, false, false, processorData)
        );
    }

    function _relayBridgeFinalize(uint256 nonce, address from, uint256 amount) internal {
        vm.selectFork(_l2Fork);
        vm.prank(_computeAlias(_l1CrossDomainMessenger()));
        _l2Messenger().relayMessage(
            nonce,
            _l1StandardBridge(),
            _l2StandardBridge(),
            0,
            _BRIDGE_MIN_GAS_LIMIT,
            _buildBridgeFinalizeMessage(from, amount)
        );
    }

    function _relayProcessorMessage(
        uint256 nonce,
        address l1Sender,
        address beneficiary,
        uint256 amount,
        uint256 senderNonce
    ) internal returns (bytes32 messageHash) {
        bytes memory message = _buildProcessorRelayMessage(beneficiary, amount, senderNonce);
        messageHash = _hashCrossDomainMessageV1(
            nonce,
            l1Sender,
            address(_relayer),
            0,
            _PROCESSOR_MIN_GAS_LIMIT,
            message
        );

        vm.selectFork(_l2Fork);
        vm.prank(_computeAlias(_l1CrossDomainMessenger()));
        _l2Messenger().relayMessage(
            nonce,
            l1Sender,
            address(_relayer),
            0,
            _PROCESSOR_MIN_GAS_LIMIT,
            message
        );
    }

    function _relayProcessorMessageWithGas(
        uint256 nonce,
        address l1Sender,
        address beneficiary,
        uint256 amount,
        uint256 senderNonce,
        uint256 callGas
    ) internal returns (bytes32 messageHash) {
        bytes memory message = _buildProcessorRelayMessage(beneficiary, amount, senderNonce);
        messageHash = _hashCrossDomainMessageV1(
            nonce,
            l1Sender,
            address(_relayer),
            0,
            _PROCESSOR_MIN_GAS_LIMIT,
            message
        );

        vm.selectFork(_l2Fork);
        vm.prank(_computeAlias(_l1CrossDomainMessenger()));
        (bool ok,) = address(_l2Messenger()).call{gas: callGas}(
            abi.encodeCall(
                ICrossDomainMessenger.relayMessage,
                (nonce, l1Sender, address(_relayer), 0, _PROCESSOR_MIN_GAS_LIMIT, message)
            )
        );
        assertTrue(ok, "relayMessage low-gas call should not revert");
    }

    function _logExists(Vm.Log[] memory entries, address emitter, bytes32 topic0) internal pure returns (bool) {
        for (uint256 i = 0; i < entries.length; ++i) {
            if (entries[i].emitter == emitter && entries[i].topics.length > 0 && entries[i].topics[0] == topic0) {
                return true;
            }
        }
        return false;
    }

    function _relayedMessageLogExists(Vm.Log[] memory entries, address messenger, bytes32 messageHash)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < entries.length; ++i) {
            if (
                entries[i].emitter == messenger && entries[i].topics.length > 1
                    && entries[i].topics[0] == _RELAYED_MESSAGE_TOPIC0 && entries[i].topics[1] == messageHash
            ) {
                return true;
            }
        }
        return false;
    }

    function _failedMessageLogExists(Vm.Log[] memory entries, address messenger, bytes32 messageHash)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < entries.length; ++i) {
            if (
                entries[i].emitter == messenger && entries[i].topics.length > 1
                    && entries[i].topics[0] == _FAILED_RELAYED_MESSAGE_TOPIC0 && entries[i].topics[1] == messageHash
            ) {
                return true;
            }
        }
        return false;
    }

    function testBridgeAndRelaySuccess() public {
        uint256 amount = 10e18;

        vm.selectFork(_l1Fork);
        uint256 bridgeNonce = _l1Messenger().messageNonce();
        uint256 processorNonce = _incrementVersionedNonce(bridgeNonce);

        vm.startPrank(_alice);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 0, "sender nonce should start at zero");
        _l1Token.approve(address(_l1Sender), amount);
        _l1Sender.bridgeToVault(
            _l1Token,
            address(_l2Token),
            address(_relayer),
            address(_processor),
            _beneficiary,
            amount,
            _BRIDGE_MIN_GAS_LIMIT,
            _PROCESSOR_MIN_GAS_LIMIT
        );
        vm.stopPrank();

        assertEq(_l1Sender.nextNonce(_l2ChainId()), 1, "sender nonce should increment after sending");

        assertEq(_l1Bridge().deposits(address(_l1Token), address(_l2Token)), amount, "l1 deposit not tracked");
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 1, "sender nonce should increment after sending");

        vm.selectFork(_l2Fork);
        vm.recordLogs();

        _relayBridgeFinalize(bridgeNonce, address(_l1Sender), amount);
        assertEq(_l2Token.balanceOf(address(_relayer)), amount, "relayer not funded by bridge finalize");

        bytes32 processorHash = _relayProcessorMessage(processorNonce, address(_l1Sender), _beneficiary, amount, 0);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertEq(_l2Token.balanceOf(address(_relayer)), 0, "relayer should be empty after processing");
        assertEq(_l2Token.balanceOf(address(_vault)), amount, "vault did not receive bridged tokens");
        assertEq(_vault.totalAssets(), amount, "vault assets mismatch");
        assertEq(_vault.totalSupply(), amount, "vault share supply mismatch");
        assertEq(_vault.balanceOf(_beneficiary), amount, "beneficiary shares mismatch");
        assertTrue(_l2Messenger().successfulMessages(processorHash), "processor message not marked successful");

        vm.selectFork(_l1Fork);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 1, "sender nonce should remain one after successful relay");

        vm.selectFork(_l2Fork);
        assertEq(_relayer.nextNonce(address(_l1Sender)), 1, "sender nonce not incremented");

        assertTrue(_logExists(entries, address(_relayer), _TOKEN_TRANSFER_RELAYED_TOPIC0), "missing relayer event");
        assertTrue(_logExists(entries, address(_vault), _VAULT_DEPOSIT_TOPIC0), "missing vault deposit event");
        assertTrue(
            _relayedMessageLogExists(entries, _l2CrossDomainMessenger(), processorHash),
            "missing messenger relayed event"
        );
    }

    function testUnauthorizedSenderMarksMessageFailed() public {
        uint256 amount = 5e18;
        address unauthorizedSender = makeAddr("unauthorizedSender");
        uint256 bridgeNonce = _encodeVersionedNonce(50, 1);
        uint256 processorNonce = _encodeVersionedNonce(51, 1);

        _relayBridgeFinalize(bridgeNonce, address(_l1Sender), amount);

        vm.selectFork(_l2Fork);
        vm.recordLogs();
        bytes32 processorHash = _relayProcessorMessage(processorNonce, unauthorizedSender, _beneficiary, amount, 0);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertTrue(_l2Messenger().failedMessages(processorHash), "unauthorized message should fail");
        assertFalse(_l2Messenger().successfulMessages(processorHash), "unauthorized message should not succeed");
        assertEq(_l2Token.balanceOf(address(_relayer)), amount, "relayer balance should remain untouched");
        assertEq(_vault.totalAssets(), 0, "vault should not receive funds");
        assertEq(_vault.balanceOf(_beneficiary), 0, "beneficiary should not receive shares");

        vm.selectFork(_l1Fork);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 0, "sender nonce should remain zero when sender helper did not originate message");

        vm.selectFork(_l2Fork);
        assertEq(_relayer.nextNonce(unauthorizedSender), 0, "unauthorized sender nonce should remain zero");
        assertTrue(
            _failedMessageLogExists(entries, _l2CrossDomainMessenger(), processorHash),
            "missing failed relay event"
        );
    }

    function testReplayProtectionRevertsOnSecondRelay() public {
        uint256 amount = 7e18;

        vm.selectFork(_l1Fork);
        uint256 bridgeNonce = _l1Messenger().messageNonce();
        uint256 processorNonce = _incrementVersionedNonce(bridgeNonce);

        vm.startPrank(_alice);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 0, "sender nonce should start at zero");
        _l1Token.approve(address(_l1Sender), amount);
        _l1Sender.bridgeToVault(
            _l1Token,
            address(_l2Token),
            address(_relayer),
            address(_processor),
            _beneficiary,
            amount,
            _BRIDGE_MIN_GAS_LIMIT,
            _PROCESSOR_MIN_GAS_LIMIT
        );
        vm.stopPrank();

        assertEq(_l1Sender.nextNonce(_l2ChainId()), 1, "sender nonce should increment after sending");

        _relayBridgeFinalize(bridgeNonce, address(_l1Sender), amount);
        _relayProcessorMessage(processorNonce, address(_l1Sender), _beneficiary, amount, 0);

        vm.selectFork(_l2Fork);
        vm.prank(_computeAlias(_l1CrossDomainMessenger()));
        vm.expectRevert("CrossDomainMessenger: message has already been relayed");
        _l2Messenger().relayMessage(
            processorNonce,
            address(_l1Sender),
            address(_relayer),
            0,
            _PROCESSOR_MIN_GAS_LIMIT,
            _buildProcessorRelayMessage(_beneficiary, amount, 0)
        );
    }

    function testDuplicateSenderNonceMarksMessageFailed() public {
        uint256 amount = 8e18;
        uint256 bridgeNonce1 = _encodeVersionedNonce(60, 1);
        uint256 processorNonce1 = _encodeVersionedNonce(61, 1);
        uint256 bridgeNonce2 = _encodeVersionedNonce(62, 1);
        uint256 processorNonce2 = _encodeVersionedNonce(63, 1);

        _relayBridgeFinalize(bridgeNonce1, address(_l1Sender), amount);
        _relayProcessorMessage(processorNonce1, address(_l1Sender), _beneficiary, amount, 0);

        vm.selectFork(_l1Fork);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 0, "manual relays should not mutate sender helper nonce");

        vm.selectFork(_l2Fork);
        _relayBridgeFinalize(bridgeNonce2, address(_l1Sender), amount);

        vm.selectFork(_l2Fork);
        vm.recordLogs();
        bytes32 processorHash = _relayProcessorMessage(processorNonce2, address(_l1Sender), _beneficiary, amount, 0);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertTrue(_l2Messenger().failedMessages(processorHash), "duplicate sender nonce should fail");
        assertFalse(_l2Messenger().successfulMessages(processorHash), "duplicate sender nonce should not succeed");

        vm.selectFork(_l1Fork);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 0, "sender helper nonce should remain zero in manual duplicate test");

        vm.selectFork(_l2Fork);
        assertEq(_relayer.nextNonce(address(_l1Sender)), 1, "sender nonce should remain unchanged after duplicate relay");
        assertEq(_l2Token.balanceOf(address(_relayer)), amount, "relayer should retain second bridged amount");
        assertTrue(
            _failedMessageLogExists(entries, _l2CrossDomainMessenger(), processorHash),
            "missing failed relay event for duplicate sender nonce"
        );
    }

    function testInsufficientGasMarksMessageFailed() public {
        uint256 amount = 9e18;
        uint256 bridgeNonce = _encodeVersionedNonce(80, 1);
        uint256 processorNonce = _encodeVersionedNonce(81, 1);

        _relayBridgeFinalize(bridgeNonce, address(_l1Sender), amount);

        vm.selectFork(_l2Fork);
        vm.recordLogs();
        bytes32 processorHash =
            _relayProcessorMessageWithGas(processorNonce, address(_l1Sender), _beneficiary, amount, 0, 200_000);
        Vm.Log[] memory entries = vm.getRecordedLogs();

        assertTrue(_l2Messenger().failedMessages(processorHash), "low gas should mark message failed");
        assertFalse(_l2Messenger().successfulMessages(processorHash), "low gas message should not succeed");
        assertEq(_l2Token.balanceOf(address(_relayer)), amount, "relayer balance should remain after failed relay");
        assertEq(_vault.totalAssets(), 0, "vault should not receive funds on failed relay");
        assertEq(_vault.balanceOf(_beneficiary), 0, "beneficiary should not receive shares");

        vm.selectFork(_l1Fork);
        assertEq(_l1Sender.nextNonce(_l2ChainId()), 0, "sender helper nonce should remain zero in manual low-gas test");

        vm.selectFork(_l2Fork);
        assertEq(_relayer.nextNonce(address(_l1Sender)), 0, "sender nonce should not increment after failed relay");
        assertTrue(
            _failedMessageLogExists(entries, _l2CrossDomainMessenger(), processorHash),
            "missing failed relay event"
        );
    }
}

contract TokenTransferRelayer_Superchain_MainnetFork_Test is SuperchainPackageTestBase {
    function _l1RpcAlias() internal pure override returns (string memory) {
        return "ethereum_mainnet_alchemy";
    }

    function _l2RpcAlias() internal pure override returns (string memory) {
        return "base_mainnet_alchemy";
    }

    function _l1ForkBlock() internal pure override returns (uint256) {
        return ETHEREUM_MAIN.DEFAULT_FORK_BLOCK;
    }

    function _l2ForkBlock() internal pure override returns (uint256) {
        return BASE_MAIN.DEFAULT_FORK_BLOCK;
    }

    function _l1CrossDomainMessenger() internal pure override returns (address) {
        return ETHEREUM_MAIN.BASE_L1_CROSS_DOMAIN_MESSENGER;
    }

    function _l1StandardBridge() internal pure override returns (address) {
        return ETHEREUM_MAIN.BASE_L1_STANDARD_BRIDGE;
    }

    function _l2CrossDomainMessenger() internal pure override returns (address) {
        return BASE_MAIN.L2_CROSSDOMAIN_MESSENGER;
    }

    function _l2StandardBridge() internal pure override returns (address) {
        return BASE_MAIN.L2_STANDARD_BRIDGE;
    }

    function _l2MintableFactory() internal pure override returns (address) {
        return BASE_MAIN.OPTIMISM_MINTABLE_ERC20_FACTORY;
    }

    function _permit2() internal pure override returns (address) {
        return BASE_MAIN.PERMIT2;
    }

    function _l2ChainId() internal pure override returns (uint256) {
        return BASE_MAIN.CHAIN_ID;
    }
}

contract TokenTransferRelayer_Superchain_SepoliaFork_Test is SuperchainPackageTestBase {
    function _l1RpcAlias() internal pure override returns (string memory) {
        return "ethereum_sepolia_alchemy";
    }

    function _l2RpcAlias() internal pure override returns (string memory) {
        return "base_sepolia_alchemy";
    }

    function _l1ForkBlock() internal pure override returns (uint256) {
        return ETHEREUM_SEPOLIA.DEFAULT_FORK_BLOCK;
    }

    function _l2ForkBlock() internal pure override returns (uint256) {
        return BASE_SEPOLIA.DEFAULT_FORK_BLOCK;
    }

    function _l1CrossDomainMessenger() internal pure override returns (address) {
        return ETHEREUM_SEPOLIA.BASE_L1_CROSS_DOMAIN_MESSENGER;
    }

    function _l1StandardBridge() internal pure override returns (address) {
        return ETHEREUM_SEPOLIA.BASE_L1_STANDARD_BRIDGE;
    }

    function _l2CrossDomainMessenger() internal pure override returns (address) {
        return BASE_SEPOLIA.L2_CROSSDOMAIN_MESSENGER;
    }

    function _l2StandardBridge() internal pure override returns (address) {
        return BASE_SEPOLIA.L2_STANDARD_BRIDGE;
    }

    function _l2MintableFactory() internal pure override returns (address) {
        return BASE_SEPOLIA.OPTIMISM_MINTABLE_ERC20_FACTORY;
    }

    function _permit2() internal pure override returns (address) {
        return BASE_SEPOLIA.PERMIT2;
    }

    function _l2ChainId() internal pure override returns (uint256) {
        return BASE_SEPOLIA.CHAIN_ID;
    }
}