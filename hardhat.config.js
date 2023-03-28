// require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy-ethers");
require("@typechain/ethers-v5");
const { config } = require("dotenv");
require("dotenv").config()
config();

/** @type import('hardhat/config').HardhatUserConfig */
const LOCAL_HOST_URL = process.env.LOCAL_HOST_URL;
const LOCAL_HOST_ACCOUNT = process.env.LOCAL_HOST_ACCOUNT;
const SEPOLIA_ACCOUNT = process.env.SEPOLIA_ACCOUNT;
const SEPOLIA_URL = process.env.SEPOLIA_URL;
module.exports = {
	defaultNetwork: "hardhat",
	solidity: {
		version: "0.8.7",
	},

	namedAccounts: {
		deployer: {
			default: 0,
		},
		player: {
			default: 1,
		},
	},
	networks: {
		localHost: {
			url: LOCAL_HOST_URL,
			chainId: 31337,
			accounts: [LOCAL_HOST_ACCOUNT],
			blockConfirmations: 1,
		},
		sepolia: {
			accounts: [SEPOLIA_ACCOUNT],
			blockConfirmations: 6,
			url: SEPOLIA_URL,
			chainId: 11155111,
		},
	},
};

