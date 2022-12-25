// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/Common.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Bank is IBank, ReentrancyGuard, Pausable, Ownable {
    // Rate limiting method
    uint public withdrawalWaitingPeriod;

    /**@dev Rate-limiting: 
     * Mapping of account Id to pending withdrawals
     */
    mapping (bytes32 => PendingWithdrawal) public withdrawalRequests;

    ///@dev Completely signed and created accounts
    mapping (bytes32 => JointAccountData) private jointAccountLedger;

    ///@dev Jointaccount holders record
    mapping (address => bool) private jointAccountHolders;

    /**@dev Reverse map address to account Id 
     * maps both partners account to their account Id
     */
    mapping(address => bytes32) private reverseMapJointAccountID;

    // Caller must be a joint account operator
    modifier isJointAccountHolder() {
        require(jointAccountHolders[msg.sender], "Not a joint account holder");
        _;
    }

    // Caller must not have operate a joint account by now.
    modifier isNotJointAccountHolder() {
        require(!jointAccountHolders[msg.sender], "Not a joint account holder");
        _;
    }

    // Checks that the caller is a contract account
    modifier isContractAddress() {
        require(Address.isContract(msg.sender), "EOA not allowed");
        _;
    }

    // Caller must either be PartnerA or PartnerB if both already operate a joint account
    modifier isPartnerAOrB() {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        JointAccountData memory jdata = jointAccountLedger[accountId];
        require(
            msg.sender == jdata.partnerA || msg.sender == jdata.partnerB,
            "Invalid account Id"
        );
        _;
    }

    constructor(uint _withdrawalWaitingPeriodInMinutes) {
        withdrawalWaitingPeriod = _withdrawalWaitingPeriodInMinutes * 1 minutes;
    }

    /**@dev Final withdrawal only if wait period has elapsed.
     * Note: Within the wait period, either of the partners can take action
     *       if they feel something has gone wrong.
     */
    function withdraw() external isJointAccountHolder nonReentrant isContractAddress {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        PendingWithdrawal memory pWith = withdrawalRequests[accountId];
        // Check
        require(pWith.inQueue, "Withdrawal not initiated");
        uint currentTime = block.timestamp;
        if(currentTime < pWith.timeInitiated) revert WithdrawalTimeUndermined(currentTime);
        
        // Effect
        delete withdrawalRequests[accountId];

        // Interaction
        (bool done, ) = msg.sender.call{value: pWith.amount}("");
        require(done, "failed");

    }

    // Either of the joint operators can cancel pending request.
    function cancelWithdrawalRequest() external isJointAccountHolder isPartnerAOrB isContractAddress returns(bool) {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        require(!withdrawalRequests[accountId].inQueue, "Cannot cancel request at this time");
        delete withdrawalRequests[accountId];
        return true;
    }

    /**@dev Withdraws from joint account.
     * At least one partner must have signed the withdrawal
     */
    function initiateWithdrawal() external isJointAccountHolder isPartnerAOrB isContractAddress returns(bool) {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        uint bankBalance = address(this).balance;
        JointAccountData memory jdata = jointAccountLedger[accountId];
        PendingWithdrawal memory pWith = withdrawalRequests[accountId];

        // check
        if(jdata.accountWithdrawalSignature.signer == msg.sender) revert Partner2SignatureIsRequired(); 
        if(pWith.amount == 0) revert NoWithdrawalRequest();
        require(
            !jdata.isPending &&
            jdata.accountWithdrawalSignature.count == 1 && 
            jdata.balances >= pWith.amount,
            "Something not right"
        );
        require(bankBalance > pWith.amount, "Insufficient balance in bank");
        
        // Effect
        jointAccountLedger[accountId].balances -= pWith.amount;
        jointAccountLedger[accountId].accountWithdrawalSignature.count = 0; // Clear the signature immediately.
        withdrawalRequests[accountId].timeInitiated = block.timestamp + withdrawalWaitingPeriod; // Rate limit in force
        withdrawalRequests[accountId].inQueue = true;
        
        // In this case, we use Rate limiting, so interaction did not take place.
        emit WithdrawalInitiated(pWith.amount, accountId);

        return true;
    }

    // Any of the partners can deposit into their joint acccount
    function deposit(bytes32 accountId) external payable isJointAccountHolder isPartnerAOrB returns(bool) {
        jointAccountLedger[accountId].balances += msg.value;

        return true;
    }

    // Returns the balance in join account of the caller, only if they're joint account operator.
    function getBalance() external view isJointAccountHolder returns(uint256) {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        return jointAccountLedger[accountId].balances;
    }

    function _createJointId(address a, address b) internal pure returns(bytes32) {
        return keccak256(abi.encode(a, b));
    }

    // We implemented circuit breaker here using "whenNotPaused" modifier
    function createJoinAccount(address partner) external payable whenNotPaused isContractAddress returns(bytes32 accountId, bool isPending) {
        require(Address.isContract(partner), "Not a contract account");
        require(
            Common(msg.sender).getEligibility() && 
            Common(partner).getEligibility(),
            "Not eligible"
        );
        if(jointAccountHolders[partner]) revert AlreadyAJoinPartner(partner);
        if(jointAccountHolders[msg.sender]) revert AlreadyAJoinPartner(msg.sender);
        accountId = _createJointId(msg.sender, partner);
        reverseMapJointAccountID[msg.sender] = accountId;
        isPending = true;
        jointAccountLedger[accountId] = JointAccountData(
            msg.sender,
            partner,
            Signature(msg.sender, 1), // msg.sender auto signs account creation. Account will only be opened is partnerB signs.
            0,
            msg.value,
            0,
            isPending
        );

        emit JoinAccountCreated(accountId);

        return (accountId, isPending);
    }

    /*@dev PartnerB signs joint account creation.
    * Note Account must be pending.
    */
    function signJointAccountCreation(bytes32 accountId) external payable isContractAddress isNotJointAccountHolder returns(bool) {
        require(jointAccountLedger[accountId].isPending, "Invalid account");
        require(jointAccountLedger[accountId].partnerB == msg.sender, "Not authorized");
        jointAccountLedger[accountId].isPending = false;
        jointAccountLedger[accountId].balances += msg.value;
        jointAccountHolders[msg.sender] = true;
        reverseMapJointAccountID[msg.sender] = accountId;

        return true;
    }

    // Either of the partner signs withdrawal request
    function signWithdrawalRequest(bytes32 accountId, uint amount) external isJointAccountHolder isContractAddress returns(bool) {
        JointAccountData memory jdata = jointAccountLedger[accountId];
        require(jdata.accountWithdrawalSignature.count == 0, "Already signed");
        require(
            msg.sender == jdata.partnerA || msg.sender == jdata.partnerB,
            "Invalid account Id"
        );
        jointAccountLedger[accountId].accountWithdrawalSignature = Signature(msg.sender, jdata.accountWithdrawalSignature.count + 1);
        withdrawalRequests[accountId] = PendingWithdrawal(
            msg.sender,
            amount,
            0,
            false
        );

        return true;
    }

    // Either of the partners can initiate account closure while await the other to execute.
    function initiateAccountClosure() external isJointAccountHolder isContractAddress returns(bool) {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        JointAccountData memory jdata = jointAccountLedger[accountId];
        require(jdata.accountCloseSignature == 0, "Already signed");
        jointAccountLedger[accountId].accountCloseSignature ++;

        return true;
    }

    /**@dev Closes joint account
     * Note: This may not be the ideal way to close a joint account. 
     *      It is intended for tutorial purpose. Do not use in production.
     */
    function closeAccount() external returns(bool) {
        bytes32 accountId = reverseMapJointAccountID[msg.sender];
        JointAccountData memory jdata = jointAccountLedger[accountId];
        require(jdata.accountCloseSignature == 1, "At least one signature is required");
        if(jdata.balances > 0) {
            uint8 multiplier = 50;
            uint share;
            unchecked {
                share = (jdata.balances * multiplier)  / 100;
            }
            (bool success,) = jdata.partnerA.call{value:share}("");
            (bool success_1,) = jdata.partnerB.call{value:share}("");
            require(success && success_1, "Account closure failed");
        }

        return true;

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

}