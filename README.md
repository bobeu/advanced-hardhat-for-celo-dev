# Sample Hardhat Project

This project demonstrates advanced Hardhat usage, And was made for tutorial purpose for Celo developers.

`Note`: The source code is not audited and so, do not deploy to production.

# How to run and test

- **Clone the repository**

```
git clone https://github.com/bobeu/advanced-hardhat-for-celo-dev.git

```

Then: 

```
cd advanced-hardhat-for-celo-dev

```

- **Install dependencies**

```
yarn install (preferably)

```

Or

```
npm install

```

- **Compiling**

```
npx hardhat compile

```

- Deployment (Alfrajores - Celo testnet)

Before running the command, create a folder called `deployments` in the project's root if it does not exist before.

```
npx hardhat deploy --network alfajores

```

-  **Testing**

```
npx hardhat test

```

# Resources

- [Celo developer resources](https://docs.celo.org/developer/)
- [Official Hardhat doc](https://hardhat.org)

## Latest Deployment info

Command
```bash
npx hardhat run scripts/deploy.js --network alfajores
```

FloatAsset deployed to 0x413c7Bd53C296187C0603f6DF4d462CB7b72Da65
Properties deployed to 0x363cbC35614F3a43F91f5419F8e5763fB7cd9921
Bank deployed to 0xddab9C5eB2A6C709dcB680f1444D4C4c0dBAE832
parent deployed to 0xd6f1eDB2c7Bd60F57a992B8370730c029e468595
husbandToBe deployed to 0x3fF767b8d694B2C6a60a015390BAeb352f328468
WifeToBe deployed to 0xa81f203Ab7E0E2ebC7b7E43CF16Bc7f108D1ef91 