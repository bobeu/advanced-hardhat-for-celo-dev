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
	console.log(deployer);
	let vrfCoordinatorV2Address,
		subscription_id,
		callBackGasLimit,
		interval,
		entranceFee,
		gasLane,
		vrfCoordinatorV2Mock,
		txnReceipt;
	const chainId = network.config.chainId;

	if (developmentChains.includes(network.name)) {
		 vrfCoordinatorV2Mock = await ethers.getContract(
			"VRFCoordinatorV2Mock"
		);
		vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address;
		entranceFee = networkConfig[chainId]["entranceFee"];

		gasLane = networkConfig[chainId]["gasLane"];

		const txnResponse = await vrfCoordinatorV2Mock.createSubscription();

		txnReceipt = await txnResponse.wait(1);

		subscription_id = txnReceipt.events[0].args.subId;
		console.log(`subscription_Id : ${subscription_id}`)


		await vrfCoordinatorV2Mock.fundSubscription( // after adding subscription
		//  we need to add  the subscription to vrfV2Mock contract.
			subscription_id,
			VRF_FUND_AMOUNT
		);

		callBackGasLimit = networkConfig[chainId]["callBackGasLimit"];

		interval = networkConfig[chainId]["interval"];
	} else if(!developmentChains.includes(network.name)){
		vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"];
		subscription_id = networkConfig[chainId["subscriptionId"]];
		callBackGasLimit = networkConfig[chainId]["callBackGasLimit"];
		interval = networkConfig[chainId]["interval"];
		gasLane = networkConfig[chainId]["gasLane"];
		
		entranceFee= networkConfig[chainId["entranceFee"]]
	}
	const args = [
		vrfCoordinatorV2Address,
		subscription_id,
		gasLane,
		interval,
		entranceFee,
		callBackGasLimit,
	];

	const lottery = await deploy("Lottery", {
		from: deployer,
		log: true,
		//waitConfirmations: network.config.blockConfirmations || 1,
		args: args,
	});
	await vrfCoordinatorV2Mock.addConsumer(
        subscription_id,
        lottery.address
    )
	

	if (!developmentChains.includes(network.name) && ETHERSCAN_API_KEY) {
		log("verifying...");
		await verify(lottery.address, args);
	}
	log("-----------------------------");
};

module.exports.tags = ["all", "raffle"];

