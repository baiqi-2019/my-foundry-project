// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./StakingInterfaces.sol";

contract KKToken is ERC20, Ownable, IToken {
    mapping(address => bool) public minters;
    
    constructor() ERC20("KK Token", "KK") Ownable(msg.sender) {}
    
    function mint(address to, uint256 amount) external override {
        require(minters[msg.sender] || msg.sender == owner(), "Not authorized to mint");
        _mint(to, amount);
    }
    
    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }
    
    function removeMinter(address minter) external onlyOwner {
        minters[minter] = false;
    }
} 