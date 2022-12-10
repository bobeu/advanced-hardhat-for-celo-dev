module.exports = async ({ getNamedAccounts, deployments}) => {
  const {deploy} = deployments;
  const {deployer, child_1, child_2} = await getNamedAccounts();
  
  console.log(child_1, child_2)

  const beneficiaries = await deploy('Beneficiaries', {
    from: deployer,
    gasLimit: 4000000,
    args: [child_1, child_2],
  });

  const bank = await deploy('Bank', {
    from: deployer,
    gasLimit: 4000000,
    value: "1000000000000000000",
    args: [beneficiaries.address],
  });

  console.log("Beneficiaries address:", beneficiaries.address)
  console.log("Bank address", bank.address,)
  console.log("Deployer", deployer) 
  console.log("Child_1 ", child_1)
  console.log("Child_2 ", child_2)

};

module.exports.tags = ['Beneficiaries', 'Bank'];