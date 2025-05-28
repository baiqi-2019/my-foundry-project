// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
    function mint(address to, uint256 amount) external;
}

interface IStaking {
    function stake() payable external;
    function unstake(uint256 amount) external; 
    function claim() external;
    function balanceOf(address account) external view returns (uint256);
    function earned(address account) external view returns (uint256);
}

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
} 