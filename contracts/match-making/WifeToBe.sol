// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./interfaces/IWifeToBe.sol";
import "./interfaces/IHusbandToBe.sol";
import "./HusbandToBe.sol";
// import "./interfaces/IParent.sol";
import "./interfaces/IBank.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WifeToBe is Context, IWifeToBe, Ownable, Pausable {
  IParent public parent;

  IHusbandToBe public husband;

  IBank private jointBank;

  bool private isReady;

  bytes32 private accountId;

  bytes32 private acceptance;

  Criteria public criteria;

  Status public status;

  modifier validateStatus(Status _status, string memory errorMessage) {
      require(status == _status, errorMessage);
      _;
      if (uint8(_status) < uint8(Status.MARRIED))
          status = Status(uint8(_status) + 1);
  }

  modifier validateCaller(address expected, string memory errorMessage) {
      require(_msgSender() == expected, errorMessage);
      _;
  }

  constructor(
      IParent _parent,
      uint8 _age,
      bool _isMale,
      bool _shouldOwnAtLeastAProperty,
      IBank _bank,
      IERC20 asset,
      IERC721 _property,
      uint8 _religionSelector,
      uint8 _natureSelector,
      uint8 _statusSelector,
      uint _minimBankBalance
  ) {
      if (address(_parent) == address(0))
          revert YouShouldAtLeastHaveARelative();
      if (address(parent) != address(0)) {
          require(_parent == parent, "False");
      }
      require(
          _religionSelector < 3 && _natureSelector < 2 && _statusSelector < 2,
          "Selector out of bound"
      );
      jointBank = _bank;
      criteria = Criteria(
          _age,
          _minimBankBalance,
          _isMale,
          _shouldOwnAtLeastAProperty,
          asset,
          _property,
          Religion(_religionSelector),
          Nature(_natureSelector),
          Status(_statusSelector)
      );
  }

  receive() external payable {
      require(msg.value > 0);
  }

  function setParent(IParent _parent) external returns(bool _return) {
    if (address(parent) == address(0)) {
        parent = _parent;
        _return = true;
    }
    return _return;
  }

  function tryPropose()
    external
    whenNotPaused
    validateStatus(Status.SINGLE, "Taken")
    returns (bool _proposalAccepted)
  {
    _proposalAccepted = true;
    Profile memory _p = IHusbandToBe(payable(_msgSender())).getProfile();
    if (_p.age < criteria.age) revert AgeTooLow();
    if (_p.gender == Gender.FEMALE) revert OnlyMalePlease();
    if (IERC20(_p.asset).balanceOf(_msgSender()) < criteria.minimBankBalance)
        revert PleaseWorkHarder();
    if (criteria.shouldOwnAtLeastAProperty) {
        if (IERC721(_p.property).balanceOf(_msgSender()) == 0)
            revert YouShouldAtLeastOwnAProperty();
    }

    require(
      _p.religion == criteria.religion &&
        _p.nature == criteria.nature &&
        _p.status == criteria.status,
      "Sorry! Not my type of man"
    );

    emit Proposal(address(this), _msgSender());
  }

  function setMarriageStatus(IHusbandToBe _husband)
    external
    whenNotPaused
    validateCaller(address(parent), "Only parent can confirm status")
    validateStatus(Status.TAKEN, "Taken")
    returns (bool)
  {
    require(address(_husband) != address(0), "Invalid husband ref");
    husband = _husband;

    emit Married(address(_husband), address(this));
    return true;
  }

  function checkStatus() external view returns (string memory _status) {
    if (status == Status.SINGLE) {
        _status = "Single";
    } else if (status == Status(1)) {
        _status = "Taken";
    } else {
        _status = "Married";
    }
  }

  function getBalance(address who) external view returns (uint256) {
    return address(who).balance;
  }

  // We implemented circuit breaker here using "whenNotPaused" modifier
  function meetYourWife()
    external
    whenNotPaused
    validateCaller(address(husband), "Taarr! no trespassing")
    validateStatus(Status.MARRIED, "Fail")
    returns (bool)
  {
    acceptance = bytes32(abi.encodePacked(_msgSender(), address(this)));
    emit Pregnancy(acceptance, _msgSender());

    return true;
  }

  function createJoinAccount() public onlyOwner {
    if (address(husband) == address(0)) revert NotYetMarried();
    (bytes32 _accountId, bool success) = IBank(jointBank).createJoinAccount(
        address(husband)
    );
    require(success, "Failed");
    accountId = _accountId;
  }

  function checkBalance() public view onlyOwner returns (uint) {
      return IBank(jointBank).getBalance();
  }

  function signJointAccountCreation() public onlyOwner {
    bytes32 _accountId = accountId;
    require(IBank(jointBank).signJointAccountCreation(_accountId), "Failed");
  }

  function signWithdrawalRequest(uint amount) public onlyOwner {
    bytes32 _accountId = accountId;
    require(
        IBank(jointBank).signWithdrawalRequest(_accountId, amount),
        "Failed"
    );
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

  function getEligibility() external view returns (bool) {
    require(msg.sender == address(jointBank), "Authorized");
    return address(husband) == address(0);
  }

  function pause() public onlyOwner {
      _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }
  
}