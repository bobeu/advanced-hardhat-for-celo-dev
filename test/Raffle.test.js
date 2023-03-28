const { assert, expect } = require("chai");
const { network, deployments, getNamedAccounts, ethers } = require("hardhat");
const {
	developmentChains,
	networkConfig,
} = require("../helper-hardhat-config");

!developmentChains.includes(network.name)
	? describe.skip
	: describe("Raffle Unit Tests", function () {
			let raffle,
				lottery,
				vrfCoordinatorV2Mock,
				raffleEntranceFee,
				interval,
				deployer;

			beforeEach(async function () {
				deployer = (await getNamedAccounts()).deployer;

				await deployments.fixture(["mocks", "raffle"]);
				vrfCoordinatorV2Mock = await ethers.getContract(
					"VRFCoordinatorV2Mock",
					deployer
				);
				lottery = await ethers.getContract("Lottery", deployer);
				raffleEntranceFee = await lottery.getEntranceFee();
				interval = await lottery.getInterval();
			});

			describe("constructor", function () {
				it("initializes the raffle correctly", async function () {
					const raffleState = await lottery.getRaffleState();
					assert.equal(raffleState, "0");

					assert.equal(interval.toString(), "30");
				});
			});

			describe("enterRaffle", function () {
				it("reverts when you don't pay enough", async () => {
					await expect(lottery.enterRaffle()).to.be.reverted;
				});
				it("records player when they enter", async () => {
					await lottery.enterRaffle({ value: raffleEntranceFee });

					const contractPlayer = await lottery.getPlayer(0);
					assert.equal(deployer, contractPlayer.toString());
				});
				it("emits event on enter", async () => {
					await expect(
						lottery.enterRaffle({ value: raffleEntranceFee })
					).to.emit(
						// emits RaffleEnter event if entered to index player(s) address
						lottery,
						"RaffleEnter"
					);
				});
				it("doesn't allow entrance when raffle is calculating", async () => {
					await lottery.enterRaffle({ value: raffleEntranceFee });

					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1
					]);// this will increase the time , so we don't have to wait for the actual time interval
					await network.provider.send("evm_mine", [] );// now we have to mine a block
					// after increatsing the time

					// we pretend to be a keeper for a second
					await lottery.performUpkeep([]); // changes the state to calculating for our comparison below
					await expect(lottery.enterRaffle({ value: raffleEntranceFee })).to.be
					.reverted;
				});
			});
			describe("CheckUpKeep", function () {
				it.only("returns false if people have not sent any eth", async function () {
					// we don't want to send a txn with checkUpKeep, rather, we just eant to
					//so we use call static
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]); // this is to skip the interval
					await network.provider.send("evm_mine", []); //this is to mine a block
					const { upKeepNeeded } = await lottery.callStatic.checkUpkeep([]);
					assert(!upKeepNeeded);
				});
				it("should return false if the raffle is not open", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]); // this is to skip the interval
					await network.provider.request({ method: "evm_mine", params: [] });

					await lottery.performUpkeep([]);
					const raffleState = await lottery.getRaffleState();
					const { upKeepNeeded } = await lottery.callStatic.checkUpkeep([]);
					assert.equal(raffleState.toString(), "1");
					assert.equal(upKeepNeeded, false);
				});

				it(" returns false if enough time hasn't passed", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() - 1,
					]); // this is to skip the interval
					await network.provider.send("evm_mine", []);

					const { upKeepNeeded } = await lottery.callStatic.checkUpkeep([]);

					assert(!upKeepNeeded);
				});

				it(" returns true if enough time hasn't passed , has players and is open", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]); // this is to skip the interval
					await network.provider.request({ method: "evm_mine", params: [] });

					const { upKeepNeeded } = await lottery.callStatic.checkUpkeep([]);
					assert(upKeepNeeded);
				});
			});
			describe("PerfomUpKeep", function () {
				it("should run if checkUpKeep is true", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]); // this is to skip the interval
					await network.provider.request({ method: "evm_mine", params: [] });
					const tx = await lottery.performUpkeep([]);
					assert(tx);
				});
			});
	  });
