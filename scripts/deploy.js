const { BigNumber } = require("bignumber.js");
const { Web3 } = require("web3");
const ethers = require("ethers");

// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const WITHDRAW_WAITING_PERIOD_IN_MINUTES = 24 * 60;
  const AGE = 30;
  const RELIGION_SELECTOR = 2;
  const NATURE_SELECTOR = 1;
  const STATUS_SELECTOR = 0;
  const IS_MALE = true;
  const SHOULD_OWN_AT_LEAST_A_PROPERTY = true;
  const BRIDE_PRICE = ethers.utils.parseUnits("100000000000000000000");
  const MINIMUM_BANK_BALANCE = ethers.utils.parseUnits("10000000000000000000");
  
  const FloatAsset = await hre.ethers.getContractFactory("FloatAsset");
  const floatAsset = await FloatAsset.deploy();
  await floatAsset.deployed();
  const ASSET = floatAsset.address;
  console.log(`FloatAsset deployed to ${floatAsset.address}`);
  
  
  const Properties = await hre.ethers.getContractFactory("Properties");
  const properties = await Properties.deploy();
  await properties.deployed();
  const PROPERTY = properties.address;
  console.log(`Properties deployed to ${properties.address}`);
  
  const Bank = await hre.ethers.getContractFactory("Bank");
  const bank = await Bank.deploy(WITHDRAW_WAITING_PERIOD_IN_MINUTES);
  await bank.deployed();
  const BANK = bank.address;
  console.log(`Bank deployed to ${bank.address}`);

  const Parent = await hre.ethers.getContractFactory("Parent");
  const parent = await Parent.deploy(BANK, BRIDE_PRICE);
  await parent.deployed();
  const PARENT = parent.address;
  console.log(`parent deployed to ${parent.address}`);
  
  const HusbandToBe = await hre.ethers.getContractFactory("HusbandToBe");
  const husbandToBe = await HusbandToBe.deploy(
    AGE,
    ASSET,
    PROPERTY,
    RELIGION_SELECTOR,
    NATURE_SELECTOR,
    STATUS_SELECTOR
  );
  await husbandToBe.deployed();
  console.log(`husbandToBe deployed to ${husbandToBe.address}`);
    
  const WifeToBe = await hre.ethers.getContractFactory("WifeToBe");
  const wifeToBe = await WifeToBe.deploy(
    PARENT,
    AGE,
    IS_MALE,
    SHOULD_OWN_AT_LEAST_A_PROPERTY,
    BANK,
    ASSET,
    PROPERTY,
    RELIGION_SELECTOR,
    NATURE_SELECTOR,
    STATUS_SELECTOR,
    MINIMUM_BANK_BALANCE
  );
  await wifeToBe.deployed();

  console.log(`WifeToBe deployed to ${wifeToBe.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
