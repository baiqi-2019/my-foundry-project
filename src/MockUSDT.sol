// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract MockUSDT is BaseERC20 {
    constructor() {
        name = "Mock USDT";
        symbol = "USDT";
        decimals = 6; // USDT通常使用6位小数
        totalSupply = 1000000000 * 10**uint256(decimals); // 10亿USDT
        
        balances[msg.sender] = totalSupply;
    }
    
    // 添加铸币功能用于测试
    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
} 