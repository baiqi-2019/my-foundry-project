// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./StakingInterfaces.sol";

contract MockWETH is ERC20, IWETH {
    constructor() ERC20("Wrapped Ether", "WETH") {}
    
    function deposit() external payable override {
        _mint(msg.sender, msg.value);
    }
    
    function withdraw(uint256 amount) external override {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }
    
    function approve(address spender, uint256 amount) public override(ERC20, IWETH) returns (bool) {
        return super.approve(spender, amount);
    }
    
    function transfer(address to, uint256 amount) public override(ERC20, IWETH) returns (bool) {
        return super.transfer(to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public override(ERC20, IWETH) returns (bool) {
        return super.transferFrom(from, to, amount);
    }
    
    function balanceOf(address account) public view override(ERC20, IWETH) returns (uint256) {
        return super.balanceOf(account);
    }
    
    receive() external payable {
        _mint(msg.sender, msg.value);
    }
} 