import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.30',
    settings: {
      "evmVersion": "prague"
    },
  },
  paths: {
    sources: "./contracts", // Adjust this if your contracts are in a different directory
    cache: "./cache",
    artifacts: "./artifacts",
    tests: "./test",
  },
};

export default config;
