// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Properties is ERC721 {
  uint public tokenId;
  uint public mintFee;

  constructor () ERC721("Burj Khalifa", "BUKHA") {
    for (uint i = 1; i < 11; i++) { 
      tokenId += i;
      _safeMint(_msgSender(), i);
    }
  }

  function safeMint() external payable returns(bool) {
    require(msg.value > mintFee, "Insufficient value");
    tokenId ++;
    _safeMint(_msgSender(), tokenId);

    return true;
  }
}