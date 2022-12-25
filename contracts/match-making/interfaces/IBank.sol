// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IBank {
  /**Note : The essence of creating an interface for Bank is so that 
   * contract accounts can as well act as operator. That way, we expand participation in our dApp.
   */
  error NoWithdrawalRequest();
  error AlreadyAJoinPartner(address);
  error Partner2SignatureIsRequired();
  error WithdrawalTimeUndermined(uint);

  event WithdrawalInitiated(uint, bytes32);
  event JoinAccountCreated(bytes32);

  struct JointAccountData {
    address partnerA;
    address partnerB;
    Signature accountWithdrawalSignature;
    uint accountCloseSignature;
    uint balances;
    uint withdrawAmount;
    bool isPending;
  }

  struct Signature {
    address signer;
    uint count;
  }

  struct PendingWithdrawal {
    address initiator;
    uint amount;
    uint timeInitiated;
    bool inQueue;
  }

  function withdraw() external;
  function getBalance() external view returns(uint256);
  function initiateWithdrawal() external returns(bool);
  function initiateAccountClosure() external returns(bool);
  function cancelWithdrawalRequest() external returns(bool);
  function deposit(bytes32 accountId) external payable returns(bool);
  function signJointAccountCreation(bytes32 accountId) external payable returns(bool);
  function signWithdrawalRequest(bytes32 accountId, uint amount) external returns(bool);
  function createJoinAccount(address partner) external payable returns(bytes32 accountId, bool success);
}