// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import "@openzeppelin/contracts/access/Ownable.sol";


contract MockToken is ERC20('SubToken', 'ST'),Ownable {

  constructor() Ownable(msg.sender) {
    _mint(msg.sender, 700000000 * (10 ** decimals()));
  }

  function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

  function ownerTransfer(address to, uint256 amount) public onlyOwner {
        require(balanceOf(owner()) >= amount, "Not enough tokens in owner's balance");
        _transfer(owner(), to, amount);
    }

}

