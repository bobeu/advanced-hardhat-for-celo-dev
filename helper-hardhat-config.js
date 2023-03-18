// get the contract address from vrfCoordinatorv2

const { ethers } = require("hardhat")

const networkConfig={
    11155111:{
        name:"sepolia",
        vrfCoordinatorv2: "0x",  // get from chainlink
        entranceFee: ethers.utils.parseEther("0.01"),
        gasLane: "0x0", // get from chainlink
        subscriptionId:"", // getFrom chainlink
        callBackGasLimit: "500000",
        interval: "30",
    },
    31337:{
        name:"hardhat",
        entranceFee:ethers.utils.parseEther("0.01"),
        callBackGasLimit:"500000",
        interval:"30"
    }
}


const developmentChains =["hardhat", "localHost"]
const BASE_FEE = ethers.utils.parseEther("0.25") // 0.25 Link, it costs 0.25 link for a request
const GAS_PRICE_LINK = 1e9
module.exports={
    networkConfig,
    developmentChains,
    BASE_FEE,
    GAS_PRICE_LINK

}