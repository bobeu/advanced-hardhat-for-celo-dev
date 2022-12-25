// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBank.sol";

interface Common {
  error InvalidBankAddress();
  error YouShouldAtLeastHaveARelative();

  enum Status { SINGLE, TAKEN, MARRIED }
  enum Religion { TRADITIONAL, ISLAMIC, CHRISTIANITY }
  enum Nature { DRUNKARD, NONDRUNKER }
  enum Gender { MALE, FEMALE }

  struct Criteria {
    uint age;
    uint minimBankBalance;
    bool gender;
    bool shouldOwnAtLeastAProperty;
    IERC20 bank;
    IERC721 property;
    Religion religion;
    Nature nature;
    Status status;
  }

  struct Profile {
    uint age;
    Gender gender;
    IERC20 asset;
    IERC721 property;
    Religion religion;
    Nature nature;
    Status status;
  }

  function getEligibility() external view returns(bool);
  
}