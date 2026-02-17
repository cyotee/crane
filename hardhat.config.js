"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
const config = {
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
exports.default = config;
