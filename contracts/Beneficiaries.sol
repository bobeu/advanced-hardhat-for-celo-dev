// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Beneficiaries {
  address immutable owner;
  
  address immutable child_1;
  address immutable child_2;

  mapping (address => bool) public approval;

  constructor (address _child_1, address _child_2) {
    require(_child_1 != address(0) && _child_2 != address(0), "Children addresses are empty");
    child_1 = _child_2;
    child_2 = _child_2;
    owner = msg.sender;
  }

  function getApproval(address child) external view returns(bool) {
    return approval[child];
  }

  function approve(address child, bool _approval) public {
    require(msg.sender == owner, "Caller not owner");
    require(child == child_1 || child == child_2, "Child not recognized");
    approval[child] = _approval;
  }

}
