// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./StakingInterfaces.sol";

contract MockLendingPool is ILendingPool {
    mapping(address => mapping(address => uint256)) public balances; // user => asset => amount
    mapping(address => uint256) public totalDeposits; // asset => total amount
    
    uint256 public constant INTEREST_RATE = 5; // 5% annual interest (simplified)
    mapping(address => uint256) public lastUpdateTime;
    
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external override {
        require(amount > 0, "Amount must be greater than 0");
        
        // Transfer tokens from sender to this contract
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
        
        // Update balances
        balances[onBehalfOf][asset] += amount;
        totalDeposits[asset] += amount;
        lastUpdateTime[onBehalfOf] = block.timestamp;
    }
    
    function withdraw(address asset, uint256 amount, address to) external override returns (uint256) {
        require(balances[to][asset] >= amount, "Insufficient balance");
        
        // Update balances
        balances[to][asset] -= amount;
        totalDeposits[asset] -= amount;
        
        // Transfer tokens back to the recipient
        IERC20(asset).transfer(to, amount);
        
        return amount;
    }
    
    function getBalance(address user, address asset) external view returns (uint256) {
        return balances[user][asset];
    }
    
    function getTotalDeposits(address asset) external view returns (uint256) {
        return totalDeposits[asset];
    }
} 