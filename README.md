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