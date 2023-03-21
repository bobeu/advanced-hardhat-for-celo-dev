const { assert } = require("chai");
const { network, getNamedAccounts, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

!developmentChains.includes(network.name)
	? describe.skip // If the network is not in the development chains, then it sshould skip
	: describe("Raffle Unit Tests", async function () {
			let lottery, vrfCoordinatorV2Mock;

			beforeEach(async function () {
				const { deployer } = await getNamedAccounts();
				await deployments.fixture(["all"]);
				lottery = await ethers.getContract("Lottery", deployer);
				vrfCoordinatorV2Mock = await ethers.getContract(
					"VRFCoordinatorV2Mock",
					deployer
				);
			});
			describe("constructor", async function () {
				it("initializes the raffle Constructor correctly", async function () {
					const lotteryState = await lottery.getRaffleState();
					assert.equal(lotteryState.toString(), "0");

					const interval = await lottery.getInterval();
					assert.equal(interval.toString(), "30");

					const last_time_stamp = await lottery.getCurrentTimeStamp();
					const expectedTimeStamp = await lottery.getLatestTimeStamp();
					assert.equal(
						last_time_stamp.toString(),
						expectedTimeStamp.toString()
					);

					const i_callbackGasLimit = await lottery.getCallBackGasLimit();
					const expectedGasLimit = "500000";
					assert.equal(
						i_callbackGasLimit.toString(),
						expectedGasLimit.toString()
					);

					const i_subscription_id = await lottery.getSubscriptionId();
					assert.equal(i_subscription_id.toString(), "1");

					const gasLane = await lottery.getGasLane();
					const expectedGasLane =
						"0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc";
					assert.equal(gasLane.toString(), expectedGasLane.toString());

					const i_entranceFee = await lottery.getEntranceFee()
					const entranceFee = ethers.utils.parseEther("0.01")
					assert.equal(i_entranceFee.toString(),entranceFee.toString() )
				});
			});
	  });
