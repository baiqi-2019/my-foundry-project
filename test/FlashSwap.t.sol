// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/FlashSwap.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";

contract FlashSwapTest is Test {
    FlashSwap public flashSwap;
    TokenA public tokenA;
    TokenB public tokenB;
    
    address public owner;
    
    function setUp() public {
        owner = address(this);
        
        // 部署代币
        tokenA = new TokenA();
        tokenB = new TokenB();
        
        // 部署闪电兑换合约
        flashSwap = new FlashSwap();
        
        console.log("TokenA deployed at:", address(tokenA));
        console.log("TokenB deployed at:", address(tokenB));
        console.log("FlashSwap deployed at:", address(flashSwap));
        console.log("Owner:", flashSwap.owner());
    }
    
    function testDeployment() public {
        assertEq(flashSwap.owner(), owner);
        assertEq(tokenA.totalSupply(), 1000000 * 1e18);
        assertEq(tokenB.totalSupply(), 1000000 * 1e18);
        assertEq(tokenA.balanceOf(owner), 1000000 * 1e18);
        assertEq(tokenB.balanceOf(owner), 1000000 * 1e18);
    }
    
    function testEmergencyWithdraw() public {
        // 给闪电兑换合约一些代币
        uint256 amount = 1000 * 1e18;
        tokenA.transfer(address(flashSwap), amount);
        
        assertEq(tokenA.balanceOf(address(flashSwap)), amount);
        
        // 紧急提取
        flashSwap.emergencyWithdraw(address(tokenA));
        
        assertEq(tokenA.balanceOf(address(flashSwap)), 0);
        assertEq(tokenA.balanceOf(owner), 1000000 * 1e18);
    }
} 