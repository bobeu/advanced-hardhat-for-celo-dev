// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IParent.sol";
import "./interfaces/IWifeToBe.sol";
import "./interfaces/IHusbandToBe.sol";
import "./interfaces/IBank.sol";

contract HusbandToBe is IHusbandToBe, Ownable, Pausable {
  IParent public inlaw;

  IWifeToBe private wifeToBe;

  IBank private jointBank;

  bool public isMarried;

  bytes32 private accountId;

  Profile public profile;

  constructor (
    uint age,
    IERC20 asset,
    IERC721 property,
    uint8 _religionSelector,
    uint8 _natureSelector,
    uint8 _statusSelector) {
      if(address(asset) == address(0)) revert InvalidBankAddress();
      require(
        _religionSelector < 3 && 
          _natureSelector < 2 && 
            _statusSelector < 2, 
              "Selector out of bound"
      );

      profile = Profile(
        age, 
        Gender.MALE, 
        asset, 
        property, 
        Religion(_religionSelector), 
        Nature(_natureSelector), 
        Status(_statusSelector)
      );
      
  }

  receive() external payable {
    require(msg.value > 0);
  }

  function payBridePrice(IWifeToBe _wifeToBe, IParent _inlaw) public onlyOwner {
    address inlaw_ = address(_inlaw);
    require(address(_wifeToBe) != address(0) && inlaw_ != address(0), "InvalidWifeOrInlaw");
    require(IERC20(_getAsset()).approve(inlaw_, _getBridePrice()), "Failed");
    if(IParent(_inlaw).getMarriageApproval(_wifeToBe)) {
      isMarried = true;
      wifeToBe = _wifeToBe;
      inlaw = _inlaw;
    }
  }

  function tryPropose() public onlyOwner { 
    require(IWifeToBe(wifeToBe).tryPropose(), "Sorry! She's taken");
  }

  function meetYourWife() public onlyOwner {
    require(IWifeToBe(wifeToBe).meetYourWife(), "Oops! something went wrong");
  }

  function spendMoney(address to, uint amount) public onlyOwner {
    require(IERC20(_getAsset()).transfer(to, amount), "Failed");
  }

  function getProfile() external view returns(Profile memory){ 
    return profile;
  }

  function getEligibility() external view returns(bool){
    require(msg.sender == address(jointBank), "Authorized");
    return isMarried;
  }

  function createJoinAccount() public onlyOwner {
    if(address(wifeToBe) == address(0)) revert NotYetMarried();
    (bytes32 _accountId, bool success) = IBank(jointBank).createJoinAccount(address(wifeToBe));
    require(success, "Failed");
    accountId = _accountId;
  }

  function checkBalance() public view onlyOwner returns(uint) {
    return IBank(jointBank).getBalance();
  }

  function signJointAccountCreation() public onlyOwner {
    bytes32 _accountId = accountId; 
    require(IBank(jointBank).signJointAccountCreation(_accountId), "Failed");
  }

  function signWithdrawalRequest(uint amount) public onlyOwner {
    bytes32 _accountId = accountId;
    require(IBank(jointBank).signWithdrawalRequest(_accountId, amount), "Failed");
  }

  function deposit() public payable onlyOwner {
    bytes32 _accountId = accountId;
    require(IBank(jointBank).deposit(_accountId), "Failed");
  }

  function initiateWithdrawal() public onlyOwner {
    require(IBank(jointBank).initiateWithdrawal(), "Failed");
  }

  function cancelWithdrawalRequest() public onlyOwner {
    require(IBank(jointBank).cancelWithdrawalRequest(), "Failed");
  }

  function withdraw() public onlyOwner {
    IBank(jointBank).withdraw();
  }

  function _getAsset() internal view returns(address _asset) { _asset = address(profile.asset); }

  function _getBridePrice() internal view returns(uint _price) { 
    _price = IParent(inlaw).getBridePrize(); 
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
}
