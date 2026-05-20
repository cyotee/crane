// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";

/// @dev Shared mainnet addresses from frax-solidity `constants.ts` (ethereum).
library FraxEthereumAddresses {
    address internal constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address internal constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
    address internal constant FPI = 0x5Ca135cB8527d76e932f34B5145575F9d8cbE08E;
    address internal constant FPIS = 0xc2544A32872A91F4A553b404C6950e89De901fdb;
    address internal constant TIMELOCK = 0x8412ebf45bAC1B340BbE8F318b928C466c4E39CA;
    address internal constant COMPTROLLER = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;
    address internal constant FRAX_AMO_MINTER = 0xcf37B62109b537fa0Cb9A90Af4CA72f6fb85E241;
    address internal constant CPI_TRACKER_ORACLE = 0x66B7DFF2Ac66dc4d6FBB3Db1CB627BBb01fF3146;
    address internal constant UNIV3_TWAP_FRAX_FPI = 0x59985D79E1e69f659f4aB97Db07A35cE73D9174B;
    address internal constant LINK = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
    address internal constant LINK_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
    address internal constant FPI_CONTROLLER_POOL = 0x2397321b301B80A1C0911d6f9ED4b6033d43cF51;
    address internal constant TWAMM_AMO = 0x11Fc7df1fb0E51f9c9AB8f575d9bbaDC92FA425B;
    address internal constant FRAXSWAP_V2_FRAX_FPI = 0xd79886841026a39cFF99321140B3c4D31314782B;
    address internal constant COMBO_ORACLE = 0x878f2059435a19C79c20318ee57657bF4543B6d4;
    address internal constant COMBO_ORACLE_UNIV2_UNIV3 = 0x1cBE07F3b3bf3BDe44d363cecAecfe9a98EC2dff;
    address internal constant FPI_ZERO = 0x26Ce2091749059a66703CD4B998156d94eC393ef;
    address internal constant ADDRESS_WITH_FRAX = 0xC564EE9f21Ed8A2d8E7e76c085740d5e4c5FaFbE;
    address internal constant FRAX_WHALE = 0xC83a1BB26dC153c009d5BAAd9855Fe90cF5A1529;
    address internal constant ADDRESS_WITH_FXS = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
    address internal constant ADDRESS_WITH_FPI = 0xF2c4592813B5B3F79aC522E4efb2C19a666e937c;
    address internal constant ADDRESS_WITH_ETH = 0x876EabF441B2EE5B5b0554Fd502a8E0600950cFa;
    address internal constant UNIV2_LP_FRAX_FXS = 0xE1573B9D29e2183B1AF0e743Dc2754979A40D237;
    address internal constant UNIV2_LP_FRAX_USDC = 0x97C4adc5d28A86f9470C70DD91Dc6CC2f20d2d4D;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant FRAXSWAP_V2_FXS_FRAX = 0x03B59Bd1c8B9F6C265bA0c3421923B93f15036Fa;
    address internal constant RAGEQUITTER_TEMPLE = 0xB12C76b92936d136Fd8264F6EFcBb06458338D97;
    address internal constant TEMPLE_FRAX_FARM = 0x10460d02226d6ef7B2419aE150E6377BdbB7Ef16;
    address internal constant TEMPLE_FRAX_LP = 0x6021444f1706f15465bEe85463BCc7d7cC17Fc03;
}

abstract contract TestBase_FraxEthereumFork is Test {
    /// @dev Tries Alchemy → Infura → public RPC. Skips the suite when all fail (e.g. HTTP 429).
    /// Cheatcode reverts are only catchable when `createSelectFork` runs in an external call.
    function _forkEthereum() internal returns (bool forked) {
        return _forkEthereumAtBlock(0);
    }

    function _forkEthereumAtBlock(uint256 blockNumber) internal returns (bool forked) {
        string[3] memory rpcNames;
        rpcNames[0] = "ethereum_mainnet_alchemy";
        rpcNames[1] = "ethereum_mainnet_infura";
        rpcNames[2] = "ethereum_mainnet_public";

        for (uint256 i = 0; i < rpcNames.length; i++) {
            try vm.rpcUrl(rpcNames[i]) returns (string memory rpc) {
                if (blockNumber == 0) {
                    try this._createFork(rpc) {
                        return true;
                    } catch {}
                } else {
                    try this._createForkAt(rpc, blockNumber) {
                        return true;
                    } catch {}
                }
            } catch {}
        }

        vm.skip(true);
        return false;
    }

    function _createFork(string memory rpc) external {
        vm.createSelectFork(rpc);
    }

    function _createForkAt(string memory rpc, uint256 blockNumber) external {
        vm.createSelectFork(rpc, blockNumber);
    }
}