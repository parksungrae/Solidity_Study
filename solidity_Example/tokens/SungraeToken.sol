// SPDX-License-Identifier:

//Create Token example

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract SungraeToken is ERC20, Ownable {
    
    contructor() ERC20("Sungrae Token", "PSR") Ownable() {}
    
    function mint(address account_, uint256 amount_) public onlyOwner {
        _mint(account_, amount_);
    }
}