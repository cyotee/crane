import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-foundry";

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: "0.8.30",
                settings: {
                    evmVersion: 'cancun',
                    optimizer: {
                        enabled: true,
                        runs: 16683,
                    }
                }
            }
        ]
    }
};

export default config;
