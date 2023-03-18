const { network } = require("hardhat");
const {
	developmentChains,
	BASE_FEE,
	GAS_PRICE_LINK,
} = require("../helper-hardhat-config");

module.exports = async function ({ getNamedAccounts, deployments }) {
	const { deploy, log } = deployments;
	const { deployer } = await getNamedAccounts();

	if (developmentChains.includes(network.name)) {
		log("Local Chain Detected !!!");
		log("Deploying!!!!!");
		//deploy a mock vrfcoordinator
		const VRFCoordinatorV2 = await deploy("VRFCoordinatorV2Mock", {
			from: deployer,
			log: true,
			args: [BASE_FEE, GAS_PRICE_LINK],
		});
		log("Mocks deployed!!!!");
		log("-----------------------------------");
	}
};

module.exports.tag = ["all", "mocks"];
