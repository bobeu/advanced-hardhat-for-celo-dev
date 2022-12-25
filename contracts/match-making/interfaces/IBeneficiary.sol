// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBeneficiary {
  function getApproval(address) external view returns(bool);
}