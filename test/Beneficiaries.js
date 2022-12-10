const { expect } = require('chai');
const { BigNumber } = require("bignumber.js");
const {ethers, getNamedAccounts} = require('hardhat');


const toBN = (x) => {
  return new BigNumber(x);
}

describe('Beneficiaries', () => {

  it('Test1: Should confirm child_1 status as false', async function () {
    await deployments.fixture(['Beneficiaries']);
    const { deployer, child_1 } = await getNamedAccounts();
    const Instance = await ethers.getContract('Beneficiaries', deployer);

    // Note: For approval, it used default account i.e account[0] which is also the deployer
    await Instance.approval(child_1).then((tx) => 
      expect(tx).to.equal(false)
    );
  });

  it('Test2: Should approve child_2', async function () {
    await deployments.fixture(['Beneficiaries']);
    const { deployer, child_2 } = await getNamedAccounts();
    const Instance = await ethers.getContract('Beneficiaries', deployer);

    // At this point, child_2 is not approved
    await Instance.approval(child_2).then((tx) => 
      expect(tx).to.equal(false)
    );

    // Here the owner approve child_2
    await Instance.approve(child_2, true);

    // And we can verify if child_2 is truly approved.
    await Instance.approval(child_2).then((tx) => 
      expect(tx).to.equal(true)
    );
  });
  
  it('Test3 :Should withdraw successfully', async function () {
    await deployments.fixture(['Beneficiaries', 'Bank']);
    const { deployer, child_1, child_2 } = await getNamedAccounts();
    const Beneficiaries = await ethers.getContract('Beneficiaries', deployer, child_1, child_2);
    const Bank = await ethers.getContract('Bank', deployer);
    const initialBalance = await Bank.getBalance(child_2);
    const bankBalance = await Bank.getBalance(Bank.address);

    expect(initialBalance).to.be.gt(BigNumber(0));
    
    // Here the owner approve child_2
    await Beneficiaries.approve(child_2, true);
    const signer = await ethers.getSigner(child_2);
    await Bank.connect(signer).withdraw();

    expect(await Bank.getBalance(child_2)).to.be.gt(bankBalance);
    expect(await Bank.getBalance(Bank.address)).to.equal(BigNumber(0));

  });


});