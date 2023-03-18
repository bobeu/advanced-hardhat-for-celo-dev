//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

 error Lottery__notEnoughETHSent();
 error Lottery__unsuccessfulTxn();
 error Lottery__notOpen();
 error Lottery__upKeepNotNeeded(uint256 currentBalance, uint256 no_of_players, uint256 Raffle_state);

/** @title A Raffle Contract
    *@author Olaoye Salem
    *@notice This Contract is for creating untamperable decentralized smart contract
    *@dev This implements chainlinkVRF2 and chainLink Keepers
*/
    abstract contract Lottery is VRFConsumerBaseV2,KeeperCompatibleInterface {

    enum RaffleState{
        OPEN,
        CALCULATING
    }
   
    /*  State Variables */
    uint256 private immutable i_entranceFee;
    address[] private s_players; 
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFRIMATIONS =3;
    uint32 private constant NUM_WORDS=1;
    uint256 private s_lastBlockTimestamp;
    uint256 private immutable i_interval;
 

    /*  Events  */
    event raffleEnter(address indexed player);
    event RaffleGetWinner(uint256 indexed winner);


 /* Lotttery Variable */
   address private s_recentWinners;
    RaffleState private s_raffleState;

// vrfCoordinatorv2 is the address that does the random number verifivation
    constructor(address vrfCoordinatorv2,
    uint256 entranceFee, 
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
     )VRFConsumerBaseV2(vrfCoordinatorv2) {
        i_entranceFee=entranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorv2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit= callbackGasLimit;
        s_raffleState =RaffleState.OPEN;
        s_lastBlockTimestamp = block.timestamp;
        i_interval=interval;
    }

    function enterRaffle() public payable {
        if(msg.value<i_entranceFee){
            revert Lottery__notEnoughETHSent();
        }


        if(s_raffleState != RaffleState.OPEN){
            revert Lottery__notOpen();
        }
        s_players.push(payable(msg.sender));
       emit raffleEnter(msg.sender); 
    }

     function performUpkeep(bytes memory /* performData*/)external override {
         // request a random number
         // do something with it 
         // chainlink is a 2 txn process
       (bool upKeepNeeded,)= checkUpKeep("");
       if(!upKeepNeeded){
           revert Lottery__upKeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
       }
         s_raffleState = RaffleState.CALCULATING;
          uint256 requestId =i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFRIMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
          );
          emit RaffleGetWinner(requestId);
     }


     /**
     * @dev This is the function that the ChainLink Keeper nodes call
     * they look for the `upKeepNeeded `  to return true
     * The following should be true in order to return true:
     * 1. Our time intervla should have passed
     * 2. The lottery should have at least 1, player and some ETH
     * 3. Our subscription is funded with link
     * 4. Lottery should be in ann  open state
     */

        function checkUpKeep(bytes memory /*checkData*/) public   returns(bool upKeepNeeded,bytes memory/*performData*/){
            bool isOpen = (RaffleState.OPEN==s_raffleState);
            bool timePassed = (block.timestamp - s_lastBlockTimestamp)>i_interval;
            bool hasPlayers = (s_players.length>0);
            bool hasBalance= address(this).balance >0;
             upKeepNeeded=(isOpen && timePassed && hasPlayers && hasBalance);
        }
     function fulfillRandomWords(uint256 /*requestId*/,uint256[] memory randomWords) internal override{
         uint256 indexedWinner =  randomWords[0]%s_players.length ;
         address  recentWinners = s_players[indexedWinner];
         s_recentWinners = recentWinners;
         s_raffleState =RaffleState.OPEN;
         s_players = new address[](0);
         s_lastBlockTimestamp= block.timestamp;
         (bool success,) =recentWinners.call{value: address(this).balance}("");
         if(!success){
            
             revert Lottery__unsuccessfulTxn();
         }

     }

    function getEntranceFee() public view returns(uint256){
        return i_entranceFee;
    }

    function getPlayer(uint256 index) public view returns(address){
        return s_players[index];
    }
    function getRecentWinner() public view returns(address){
        return s_recentWinners;
    }
    function getRaffleState() public view returns(RaffleState){
        return s_raffleState;
    }
    function getNumberOFWords()public pure returns(uint256){
        return NUM_WORDS;
    }
    function getNumberOfPlayers() public view  returns(uint256){
        return s_players.length;
    }
    function getLatestTimeStamp()public view returns(uint256){
        return s_lastBlockTimestamp;
    }
}



// pick random winner from chainlink
// Then use chainlink keepers to grt an automated timr to pick winner   