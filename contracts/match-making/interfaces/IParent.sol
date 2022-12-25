// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Common.sol";
import "./IWifeToBe.sol";
import "./IHusbandToBe.sol";

interface IParent is Common{
  error NotApprovedForPricePayment(address);
  error ProposerAlreadyApproved(address);
  error ApprovalAlreadyGivenToSomeone();
  error InsufficientBridePrice();
  error UnresolvedPayment();

  struct Daughter {
    bool pricePaymentApproved;
    bool isOurDaughter;
    uint bridePrice;
    IHusbandToBe marriedTo;
  }

  function getMarriageApproval(IWifeToBe _daughter) external returns(bool);
  function getBridePrize() external view returns(uint);
  // function payBridePrice() external returns(bool);
}