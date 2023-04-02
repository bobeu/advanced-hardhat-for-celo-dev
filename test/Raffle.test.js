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
						interval.toNumber() + 1,
					]); // this will increase the time , so we don't have to wait for the actual time interval
					await network.provider.send("evm_mine", []); // now we have to mine a block
					// after increatsing the time

					// we pretend to be a keeper for a second
					await lottery.performUpkeep([]); // changes the state to calculating for our comparison below
					await expect(lottery.enterRaffle({ value: raffleEntranceFee })).to.be
						.reverted;
				});
			});
			describe("CheckUpKeep", function () {
				it("returns false if people have not sent any eth", async function () {
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
					await network.provider.send("evm_mine", []);

					await lottery.performUpkeep([]);

					const { upKeepNeeded } = await lottery.callStatic.checkUpkeep([]);

					assert(!upKeepNeeded);
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

				it(" returns true if enough time has passed , has players and is open", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]); // this is to skip the interval
					await network.provider.send("evm_mine", []);

					const { upKeepNeeded } = await lottery.callStatic.checkUpkeep([]);
					assert(!upKeepNeeded);
				});
			});
			describe("PerfomUpKeep", function () {
				it("should run if checkUpKeep is true", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]); // this is to skip the interval
					await network.provider.request({ method: "evm_mine", params: [] });
					const txnResponse = await lottery.performUpkeep([]);
					assert(txnResponse);
				});
				it("reverts when checkUpKeep is false", async function () {
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]);
					await network.provider.send("evm_mine", []);

					await expect(lottery.performUpkeep([])).to.be.reverted;
				});
				it("should check for if the raffle state is updated, emits an event ", async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]);
					await network.provider.send("evm_mine", []);
					const txnResponse = await lottery.performUpkeep([]);
					const txnReceipt = await txnResponse.wait(1);
					const requestId = await txnReceipt.events[1].args.requestId;
					const raffleState = await lottery.getRaffleState();
					console.log(raffleState.toString());
					assert(requestId.toString() > 0);
					assert(raffleState.toString() == "1");
				});
			});

			describe("fulfillRandomWords", function () {
				beforeEach(async function () {
					await lottery.enterRaffle({ value: raffleEntranceFee });
					await network.provider.send("evm_increaseTime", [
						interval.toNumber() + 1,
					]);
					await network.provider.send("evm_mine", []);
				});
				let recentWinner;
				it("can only be called after performUpKeep", async function () {
					await expect(
						vrfCoordinatorV2Mock.fulfillRandomWords(0, lottery.address)
					).to.be.reverted;
					await expect(
						vrfCoordinatorV2Mock.fulfillRandomWords(1, lottery.address)
					).to.be.reverted;
				});

				// we want to write a very big test

				it("picks a winner, resets the lottery and send money ", async function () {
					const additionalEntrants = 3;
					const startingAccountIndex = 1; // deployer =0
					const accounts = await ethers.getSigners();
					for (let i = startingAccountIndex; i < additionalEntrants; i--) {
						// we want to connect all the accounts to the lottery contract
						const accountConnectedRaffle = lottery.connect(accounts[i]);
						await accountConnectedRaffle.enterRaffle({
							value: raffleEntranceFee,
						});

						const startingTimeStamp = await lottery.getLatestTimeStamp();
						// we want to call perfromUpKeep (mock being chainlink keepers)
						// fufill RandomWords (mock being the chainlinkVRF)
						// we will have to wait for the fufill randomWords to be called
						//we don't just want to skip, we want to stimulate everything and wait, therefore,
						// we need to create a listener for the txn
						await new Promise(async (resolve, reject) => {
							lottery.once("WinnerPicked", async () => {
								// this is to listen to the event "winnerPicked"
								// emitted by performUpKeep
								console.log("Found The Event!!!!");
								try {
									console.log(accounts[0].address);
									console.log(accounts[1].address);
									console.log(accounts[2].address);
									console.log(accounts[3].address);

									recentWinner = await lottery.getRecentWinner();

									const raffleState = await lottery.getRaffleState();
									console.log(`recentWinner : ${recentWinner}`);
									const endingTimeStamp = await lottery.getLatestTimeStamp();
									const numPlayers = await lottery.getNumberOfPlayers();
									const winnerEndingBalance = await accounts[1].getBalance();
									
									

									assert.equal(
										winnerEndingBalance.toString(),
										winnerStartingBalance
											.add(
												raffleEntranceFee
													.mul(additionalEntrants)
													.add(raffleEntranceFee)
											)
											.toString()
									);
									assert.equal(numPlayers.toString(), 0);
									assert(endingTimeStamp > startingTimeStamp);
									assert.equal(raffleState.toString(), "0");
								} catch (e) {
									reject(e);
								}
								resolve();
							});
							// setting up a listner
							// below, we will fire the event, and the listner will pick it up and resolve
							// This part runs first before returning to the listner
							const winnerStartingBalance = await accounts[1].getBalance();
							console.log(winnerStartingBalance.toString());
							const txn = await lottery.performUpkeep([]);
							const txnReceipt = await txn.wait(1);
							await vrfCoordinatorV2Mock.fulfillRandomWords(
								txnReceipt.events[1].args.requestId,
								lottery.address
							);

						});
					}
				});
			});
	  });
