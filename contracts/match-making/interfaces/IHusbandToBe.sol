// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Common.sol";

interface IHusbandToBe is Common {
  error NotYetMarried();
  error InvalidWifeOrInlawAddress();

  function getProfile() external view returns(Profile memory);
}