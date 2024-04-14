// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockToken is ERC20 {

  address public admin;

  constructor() ERC20('MockToken', 'TKN') {
    _mint(msg.sender, 10000);
  }

  function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

}