// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./interfaces/IBeneficiary.sol";

contract Bank {
    address public immutable beneficiary;

    event Withdrawal(uint amount, address indexed who);

    constructor(address _beneficiary) payable {
        require(
           _beneficiary != address(0),
            "Beneficiary is zero address"
        );

        beneficiary = _beneficiary;
    }

    function withdraw() external {
        require(IBeneficiary(beneficiary).getApproval(msg.sender), "You're not a beneficiary");

        emit Withdrawal(address(this).balance, msg.sender);

        payable(msg.sender).transfer(address(this).balance);
    }

    function getBalance(address who) external view returns(uint256) {
        return address(who).balance;
    }
}
