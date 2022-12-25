// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Common.sol";
import "./IParent.sol";
import "./IHusbandToBe.sol";

interface IWifeToBe is Common {
  error AgeTooLow();
  error NotYetMarried();
  error OnlyMalePlease();
  error PleaseWorkHarder();
  error YouShouldAtLeastOwnAProperty();
  error OurCultureDemandsYouPayDowryFirst();

  event Proposal(address indexed who, address indexed engagedTo);
  event Married(address indexed _husband, address indexed _wife);
  event Pregnancy(bytes32 pregnacy, address indexed _husband);

  
  function checkStatus() external view returns(string memory);

  function meetYourWife() external returns(bool);
  function tryPropose() external returns(bool);
  function setParent(IParent _parent) external returns(bool);
  function setMarriageStatus(IHusbandToBe _husband) external returns(bool);
}


// contract Name {
//   address wifeToBeAddress;

//   constructor (address _wifeToBe) {
//     wifeToBeAddress = _wifeToBe;
//   }

//   modifier onlyRegistered() {
//     // logic here
//   }

//   function propose() public onlyRegistered {
//     bool _return = IWifeToBe(wifeToBeAddress).tryPropose();
//     require(_return, "Your proposal was not accepted!");
//   }
// }