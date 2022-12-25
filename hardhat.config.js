// require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require('@openzeppelin/hardhat-upgrades');
require("@nomiclabs/hardhat-ethers"); 
require('hardhat-deploy');
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy-ethers");
// require("@symfoni/hardhat-react");
// require("hardhat-typechain");
require("@typechain/ethers-v5");
const {config} = require("dotenv");

config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      live: false,
      saveDeployments: true,
      tags: ["local"]
    },

    hardhat: {
      live: false,
      saveDeployments: true,
      tags: ["test", "local"]
    },

    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 44787,
    },
 
    celo: {
      url: "https://forno.celo.org",
      accounts: [`${process.env.PRIVATE_KEY}`],
      chainId: 42220,
    },

  },

  solidity: {
    version: "0.8.9",
    settings: {          // See the solidity docs for advice about optimization and evmVersion
      optimizer: {
        enabled: true,
        runs: 200
      },
     }
  },

  paths: {
    deploy: 'deploy',
    deployments: 'deployments',
    imports: 'imports'
  },

  namedAccounts: {
    deployer: {
      default: 0,
      44787: `privatekey://${process.env.PRIVATE_KEY}`,
    },

    child_1: {
      default: 1,
      44787: process.env.CHILD_1,
    },

    child_2: {
      default: 2,
      44787 : `privatekey://${process.env.PRIVATE_KEY}`,
    }
  }
};

























// "@nomicfoundation/hardhat-network-helpers@^1.0.0" "@nomicfoundation/hardhat-chai-matchers@^1.0.0" "@nomiclabs/hardhat-ethers@^2.0.0" "@nomiclabs/hardhat-etherscan@^3.0.0" "@types/chai@^4.2.0" "@types/mocha@^9.1.0" "@typechain/ethers-v5@^10.1.0" "@typechain/hardhat@^6.1.2" "chai@^4.2.0" "hardhat-gas-reporter@^1.0.8" "solidity-coverage@^0.8.1" "ts-node@>=8.0.0" "typechain@^8.1.0"