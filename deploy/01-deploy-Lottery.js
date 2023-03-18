const { ethers, network } = require("hardhat");
const {
	developmentChains,
	networkConfig,
} = require("../helper-hardhat-config");
const { verify } = require("../utils/verify.js");

//
module.exports = async function ({ getNamedAccounts, deployments }) {
	const VRF_FUND_AMOUNT = await ethers.utils.parseEther("1");
	const { deploy, log } = deployments;
	const { deployer } = await getNamedAccounts();
	console.log(deployer)
	let vrfCoordinatorV2Address,
		subscription_id,
		callBackGasLimit,
		interval,
		entranceFee,
		gasLane,
		txnReceipt;
	const chainId = network.config.chainId;

	if (developmentChains.includes(network.name)) {
		const vrfCoordinatorV2Mock = await ethers.getContract(
			"VRFCoordinatorV2Mock"
		);
		vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;
		entranceFee = networkConfig[chainId]["entranceFee"];

		gasLane = networkConfig[chainId]["gasLane"];

		const txnResponse = await vrfCoordinatorV2Mock.createSubscription();

		txnReceipt = await txnResponse.wait(1);

		subscription_id = txnReceipt.events[0].args.subId;

		await vrfCoordinatorV2Mock.fundSubscription(
			subscription_id,
			VRF_FUND_AMOUNT
		);

		callBackGasLimit = networkConfig[chainId]["callBackGasLimit"];

		interval = networkConfig[chainId]["interval"];
	} else {
		vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
		subscription_id = networkConfig[chainId["subscriptionId"]];
		callBackGasLimit = networkConfig[chainId]["callBackGasLimit"];
		interval = networkConfig[chainId]["interval"];
	}
	const args = [
		vrfCoordinatorV2Address,
		entranceFee,
		gasLane,
		subscription_id,
		callBackGasLimit,
		interval,
	];
	console.log("1");
	console.log(` vrf Address ${vrfCoordinatorV2Address}`)
	console.log(` entranceFee  ${entranceFee}`)
	console.log(` gasLane  ${gasLane}`)
	console.log(` subscription_id  ${subscription_id}`)
	console.log(` callBackGasLimit  ${callBackGasLimit}`)
	console.log(` interval,  ${interval}`)


	


	const lottery = await deploy("Lottery", {
		from: deployer,
		log: true,
		aitConfirmations: network.config.blockConfirmations || 1,
		args: args,
	});

	if (!developmentChains.includes(network.name) && ETHERSCAN_API_KEY) {
		log("verifying..");
		await verify(lottery.address, args);
	}
	log("-----------------------------");
};
