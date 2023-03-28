// get the contract address from vrfCoordinatorv2

const { ethers } = require("hardhat");

const networkConfig = {
	11155111: {
		name: "sepolia",
		vrfCoordinatorv2: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625", // get from chainlink
		entranceFee: ethers.utils.parseEther("0.01"),

		gasLane:
			"0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c", 
            // get from chainlink
		subscriptionId: "761", // getFrom chainlink
		callBackGasLimit: "500000",
		interval: "30",
	},
	31337: {
		name: "hardhat",
		entranceFee: ethers.utils.parseEther("0.001"),
		callBackGasLimit: "500000",
		interval: "30",
		gasLane:
			"0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
			
	},
};

const developmentChains = ["hardhat", "localHost"];
const BASE_FEE = ethers.utils.parseEther("0.25"); // 0.25 Link, it costs 0.25 link for a request
const GAS_PRICE_LINK = 1e9;
module.exports = {
	networkConfig,
	developmentChains,
	BASE_FEE,
	GAS_PRICE_LINK,
};
