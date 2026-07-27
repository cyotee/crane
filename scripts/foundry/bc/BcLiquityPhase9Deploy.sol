// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {IERC20Metadata} from
    "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IWETH} from
    "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

import {AddressesRegistry} from "@crane/contracts/protocols/cdps/liquity/v2/bold/AddressesRegistry.sol";
import {ActivePool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/ActivePool.sol";
import {BoldToken} from "@crane/contracts/protocols/cdps/liquity/v2/bold/BoldToken.sol";
import {BorrowerOperations} from "@crane/contracts/protocols/cdps/liquity/v2/bold/BorrowerOperations.sol";
import {CollSurplusPool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/CollSurplusPool.sol";
import {CollateralRegistry} from "@crane/contracts/protocols/cdps/liquity/v2/bold/CollateralRegistry.sol";
import {DebtInFrontHelper} from "@crane/contracts/protocols/cdps/liquity/v2/bold/DebtInFrontHelper.sol";
import {DefaultPool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/DefaultPool.sol";
import {GasPool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/GasPool.sol";
import {HintHelpers} from "@crane/contracts/protocols/cdps/liquity/v2/bold/HintHelpers.sol";
import {MultiTroveGetter} from "@crane/contracts/protocols/cdps/liquity/v2/bold/MultiTroveGetter.sol";
import {RedemptionHelper} from "@crane/contracts/protocols/cdps/liquity/v2/bold/RedemptionHelper.sol";
import {SortedTroves} from "@crane/contracts/protocols/cdps/liquity/v2/bold/SortedTroves.sol";
import {StabilityPool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/StabilityPool.sol";
import {TroveManager} from "@crane/contracts/protocols/cdps/liquity/v2/bold/TroveManager.sol";
import {TroveNFT} from "@crane/contracts/protocols/cdps/liquity/v2/bold/TroveNFT.sol";
import {MetadataNFT, IMetadataNFT} from "@crane/contracts/protocols/cdps/liquity/v2/bold/NFTMetadata/MetadataNFT.sol";
import {FixedAssetReader} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/NFTMetadata/utils/FixedAssets.sol";
import {SSTORE2} from "@crane/contracts/external/solady/utils/SSTORE2.sol";
import {WETHPriceFeed} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/PriceFeeds/WETHPriceFeed.sol";
import {IAddressesRegistry} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IAddressesRegistry.sol";
import {IActivePool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IActivePool.sol";
import {IBoldToken} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IBoldToken.sol";
import {IBorrowerOperations} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IBorrowerOperations.sol";
import {ICollSurplusPool} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/ICollSurplusPool.sol";
import {ICollateralRegistry} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/ICollateralRegistry.sol";
import {IDefaultPool} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IDefaultPool.sol";
import {IHintHelpers} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IHintHelpers.sol";
import {IInterestRouter} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IInterestRouter.sol";
import {IMultiTroveGetter} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IMultiTroveGetter.sol";
import {IPriceFeed} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IPriceFeed.sol";
import {ISortedTroves} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/ISortedTroves.sol";
import {IStabilityPool} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IStabilityPool.sol";
import {ITroveManager} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/ITroveManager.sol";
import {ITroveNFT} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/ITroveNFT.sol";

import {
    CCR_WETH,
    MCR_WETH,
    BCR_ALL,
    SCR_WETH,
    LIQUIDATION_PENALTY_SP_WETH,
    LIQUIDATION_PENALTY_REDISTRIBUTION_WETH
} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Dependencies/Constants.sol";

/// @notice Empty InterestRouter (BOLD interface has no methods; address receives interest yield).
contract BcBoldInterestRouter is IInterestRouter {}

/// @notice Phase 9 Liquity/BOLD WETH branch deployer (CREATE2 salt graph + full setAddresses).
/// @dev Deploy this contract then call `deployWethBranch`. CREATE2 origin and Ownable owner are
///      `address(this)` so script broadcast and in-process fork tests share one path.
contract BcLiquityPhase9Deploy is Script {
    bytes32 public constant SALT = keccak256("crane-bc-bold-weth-v1");
    uint256 public constant ETH_USD_STALENESS = 24 hours;

    struct DeployResult {
        IBoldToken boldToken;
        ICollateralRegistry collateralRegistry;
        IAddressesRegistry addressesRegistry;
        IBorrowerOperations borrowerOperations;
        ITroveManager troveManager;
        ITroveNFT troveNFT;
        IMetadataNFT metadataNFT;
        IStabilityPool stabilityPool;
        IPriceFeed priceFeed;
        IActivePool activePool;
        IDefaultPool defaultPool;
        address gasPool;
        ICollSurplusPool collSurplusPool;
        ISortedTroves sortedTroves;
        IInterestRouter interestRouter;
        IHintHelpers hintHelpers;
        IMultiTroveGetter multiTroveGetter;
        RedemptionHelper redemptionHelper;
        DebtInFrontHelper debtInFrontHelper;
        IWETH weth;
        address ethUsdOracle;
    }

    struct Predicted {
        address borrowerOperations;
        address troveManager;
        address troveNFT;
        address stabilityPool;
        address activePool;
        address defaultPool;
        address gasPool;
        address collSurplusPool;
        address sortedTroves;
    }

    function getBytecode(bytes memory creationCode, address addressesRegistry)
        public
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(creationCode, abi.encode(addressesRegistry));
    }

    function predictCreate2(address deployer, bytes memory bytecode, bytes32 salt)
        public
        pure
        returns (address)
    {
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(bytecode))))));
    }

    /// @notice Deploy full WETH collateral branch + wiring. Owner of BoldToken/registry is this contract
    ///         during setup; both renounce ownership after setAddresses / setCollateralRegistry.
    function deployWethBranch(address weth, address ethUsdOracle) external returns (DeployResult memory r) {
        require(weth != address(0), "BcLiquityPhase9: WETH zero");
        require(ethUsdOracle != address(0), "BcLiquityPhase9: oracle zero");
        require(weth.code.length > 0, "BcLiquityPhase9: WETH no code");
        require(ethUsdOracle.code.length > 0, "BcLiquityPhase9: oracle no code");

        address owner = address(this);
        r.weth = IWETH(weth);
        r.ethUsdOracle = ethUsdOracle;

        // 9.1 BoldToken
        r.boldToken = new BoldToken{salt: SALT}(owner);
        require(
            address(r.boldToken)
                == predictCreate2(owner, abi.encodePacked(type(BoldToken).creationCode, abi.encode(owner)), SALT),
            "BcLiquityPhase9: BoldToken CREATE2 mismatch"
        );

        // 9.3 AddressesRegistry — hardcoded bold WETH risk params from Constants.sol
        r.addressesRegistry = new AddressesRegistry{salt: SALT}(
            owner,
            CCR_WETH,
            MCR_WETH,
            BCR_ALL,
            SCR_WETH,
            LIQUIDATION_PENALTY_SP_WETH,
            LIQUIDATION_PENALTY_REDISTRIBUTION_WETH
        );

        Predicted memory p = _predictBranch(owner, address(r.addressesRegistry));

        // 9.2 CollateralRegistry (needs predicted TM)
        IERC20Metadata[] memory collaterals = new IERC20Metadata[](1);
        collaterals[0] = IERC20Metadata(weth);
        ITroveManager[] memory troveManagers = new ITroveManager[](1);
        troveManagers[0] = ITroveManager(p.troveManager);
        r.collateralRegistry = new CollateralRegistry{salt: SALT}(r.boldToken, collaterals, troveManagers);

        // 9.9 Helpers
        r.hintHelpers = new HintHelpers{salt: SALT}(r.collateralRegistry);
        r.multiTroveGetter = new MultiTroveGetter{salt: SALT}(r.collateralRegistry);
        r.interestRouter = new BcBoldInterestRouter{salt: SALT}();

        // 9.8 PriceFeed → BC ETH/USD (needs predicted BO)
        r.priceFeed = new WETHPriceFeed{salt: SALT}(ethUsdOracle, ETH_USD_STALENESS, p.borrowerOperations);

        // MetadataNFT for TroveNFT.tokenURI
        r.metadataNFT = _deployMetadata();

        // 9.10 Full AddressVars wiring (pre-deploy predicted addresses)
        IAddressesRegistry.AddressVars memory vars = IAddressesRegistry.AddressVars({
            collToken: IERC20Metadata(weth),
            borrowerOperations: IBorrowerOperations(p.borrowerOperations),
            troveManager: ITroveManager(p.troveManager),
            troveNFT: ITroveNFT(p.troveNFT),
            metadataNFT: r.metadataNFT,
            stabilityPool: IStabilityPool(p.stabilityPool),
            priceFeed: r.priceFeed,
            activePool: IActivePool(p.activePool),
            defaultPool: IDefaultPool(p.defaultPool),
            gasPoolAddress: p.gasPool,
            collSurplusPool: ICollSurplusPool(p.collSurplusPool),
            sortedTroves: ISortedTroves(p.sortedTroves),
            interestRouter: r.interestRouter,
            hintHelpers: r.hintHelpers,
            multiTroveGetter: r.multiTroveGetter,
            collateralRegistry: r.collateralRegistry,
            boldToken: r.boldToken,
            WETH: IWETH(weth)
        });
        r.addressesRegistry.setAddresses(vars);

        // Deploy branch to predicted CREATE2 addresses
        r.borrowerOperations = new BorrowerOperations{salt: SALT}(r.addressesRegistry);
        r.troveManager = new TroveManager{salt: SALT}(r.addressesRegistry);
        r.troveNFT = new TroveNFT{salt: SALT}(r.addressesRegistry);
        r.stabilityPool = new StabilityPool{salt: SALT}(r.addressesRegistry);
        r.activePool = new ActivePool{salt: SALT}(r.addressesRegistry);
        r.defaultPool = new DefaultPool{salt: SALT}(r.addressesRegistry);
        GasPool gasPoolC = new GasPool{salt: SALT}(r.addressesRegistry);
        r.gasPool = address(gasPoolC);
        r.collSurplusPool = new CollSurplusPool{salt: SALT}(r.addressesRegistry);
        r.sortedTroves = new SortedTroves{salt: SALT}(r.addressesRegistry);

        require(address(r.borrowerOperations) == p.borrowerOperations, "BO CREATE2");
        require(address(r.troveManager) == p.troveManager, "TM CREATE2");
        require(address(r.troveNFT) == p.troveNFT, "TroveNFT CREATE2");
        require(address(r.stabilityPool) == p.stabilityPool, "SP CREATE2");
        require(address(r.activePool) == p.activePool, "AP CREATE2");
        require(address(r.defaultPool) == p.defaultPool, "DP CREATE2");
        require(r.gasPool == p.gasPool, "GasPool CREATE2");
        require(address(r.collSurplusPool) == p.collSurplusPool, "CSP CREATE2");
        require(address(r.sortedTroves) == p.sortedTroves, "ST CREATE2");

        // 9.11 Register branch on BoldToken
        r.boldToken.setBranchAddresses(
            address(r.troveManager),
            address(r.stabilityPool),
            address(r.borrowerOperations),
            address(r.activePool)
        );
        r.boldToken.setCollateralRegistry(address(r.collateralRegistry));

        IAddressesRegistry[] memory regs = new IAddressesRegistry[](1);
        regs[0] = r.addressesRegistry;
        r.redemptionHelper = new RedemptionHelper{salt: SALT}(r.collateralRegistry, regs);
        r.debtInFrontHelper = new DebtInFrontHelper{salt: SALT}(r.collateralRegistry, r.hintHelpers);

        console2.log("BcLiquityPhase9 boldToken", address(r.boldToken));
        console2.log("BcLiquityPhase9 addressesRegistry", address(r.addressesRegistry));
        console2.log("BcLiquityPhase9 borrowerOperations", address(r.borrowerOperations));
        console2.log("BcLiquityPhase9 troveManager", address(r.troveManager));
        console2.log("BcLiquityPhase9 priceFeed", address(r.priceFeed));
        console2.log("BcLiquityPhase9 collateralRegistry", address(r.collateralRegistry));
        console2.log("BcLiquityPhase9 weth", weth);
        console2.log("BcLiquityPhase9 ethUsdOracle", ethUsdOracle);
    }

    function _predictBranch(address create2Deployer, address addressesRegistry)
        internal
        pure
        returns (Predicted memory p)
    {
        p.borrowerOperations = predictCreate2(
            create2Deployer, getBytecode(type(BorrowerOperations).creationCode, addressesRegistry), SALT
        );
        p.troveManager =
            predictCreate2(create2Deployer, getBytecode(type(TroveManager).creationCode, addressesRegistry), SALT);
        p.troveNFT =
            predictCreate2(create2Deployer, getBytecode(type(TroveNFT).creationCode, addressesRegistry), SALT);
        p.stabilityPool =
            predictCreate2(create2Deployer, getBytecode(type(StabilityPool).creationCode, addressesRegistry), SALT);
        p.activePool =
            predictCreate2(create2Deployer, getBytecode(type(ActivePool).creationCode, addressesRegistry), SALT);
        p.defaultPool =
            predictCreate2(create2Deployer, getBytecode(type(DefaultPool).creationCode, addressesRegistry), SALT);
        p.gasPool =
            predictCreate2(create2Deployer, getBytecode(type(GasPool).creationCode, addressesRegistry), SALT);
        p.collSurplusPool =
            predictCreate2(create2Deployer, getBytecode(type(CollSurplusPool).creationCode, addressesRegistry), SALT);
        p.sortedTroves =
            predictCreate2(create2Deployer, getBytecode(type(SortedTroves).creationCode, addressesRegistry), SALT);
    }

    function _deployMetadata() internal returns (IMetadataNFT metadataNFT) {
        string memory root = string.concat(vm.projectRoot(), "/utils/assets/");
        bytes memory boldFile = bytes(vm.readFile(string.concat(root, "bold_logo.txt")));
        bytes memory ethFile = bytes(vm.readFile(string.concat(root, "weth_logo.txt")));
        bytes memory wstethFile = bytes(vm.readFile(string.concat(root, "wsteth_logo.txt")));
        bytes memory rethFile = bytes(vm.readFile(string.concat(root, "reth_logo.txt")));
        bytes memory geistFile = bytes(vm.readFile(string.concat(root, "geist.txt")));

        uint256 offset;
        FixedAssetReader.Asset[] memory assets = new FixedAssetReader.Asset[](5);
        assets[0] = FixedAssetReader.Asset(uint128(offset), uint128(offset + boldFile.length));
        offset += boldFile.length;
        assets[1] = FixedAssetReader.Asset(uint128(offset), uint128(offset + ethFile.length));
        offset += ethFile.length;
        assets[2] = FixedAssetReader.Asset(uint128(offset), uint128(offset + wstethFile.length));
        offset += wstethFile.length;
        assets[3] = FixedAssetReader.Asset(uint128(offset), uint128(offset + rethFile.length));
        offset += rethFile.length;
        assets[4] = FixedAssetReader.Asset(uint128(offset), uint128(offset + geistFile.length));

        bytes memory data = bytes.concat(boldFile, ethFile, wstethFile, rethFile, geistFile);
        address pointer = SSTORE2.write(data);

        bytes4[] memory sigs = new bytes4[](5);
        sigs[0] = bytes4(keccak256("BOLD"));
        sigs[1] = bytes4(keccak256("WETH"));
        sigs[2] = bytes4(keccak256("wstETH"));
        sigs[3] = bytes4(keccak256("rETH"));
        sigs[4] = bytes4(keccak256("geist"));

        FixedAssetReader reader = new FixedAssetReader{salt: SALT}(pointer, sigs, assets);
        metadataNFT = new MetadataNFT{salt: SALT}(reader);
    }
}
