// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwapCorrect.sol";

contract ExecuteFlashSwapCorrect is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address tokenA = vm.envAddress("TOKEN_A_ADDRESS");
        address tokenB = vm.envAddress("TOKEN_B_ADDRESS");
        
        // 使用环境变量中的合约地址
        address flashSwapAddress = vm.envAddress("FLASH_SWAP_CORRECT_ADDRESS");
        FlashSwapCorrect flashSwap = FlashSwapCorrect(flashSwapAddress);

        console.log("=== Execute FlashSwap Correct Arbitrage ===");
        console.log("FlashSwap Contract:", address(flashSwap));
        console.log("Token A:", tokenA);
        console.log("Token B:", tokenB);
        console.log("Owner:", vm.addr(deployerPrivateKey));

        // 检查套利机会
        console.log("\nChecking arbitrage opportunities...");
        uint256 testAmount = 10 * 1e18;
        console.log("Test amount:", testAmount / 1e18);

        (bool profitable, uint256 profitA, uint256 profitB) = flashSwap.checkArbitrageOpportunity(
            tokenA,
            tokenB,
            testAmount
        );

        console.log("Profitable:", profitable);
        console.log("Profit from borrowing A:", profitA / 1e18);
        console.log("Profit from borrowing B:", profitB / 1e18);

        if (profitable) {
            if (profitB > profitA) {
                // 从Pool B借贷更有利润
                console.log("\nExecuting arbitrage: borrow from Pool B");
                flashSwap.executeFlashSwap(tokenA, tokenB, testAmount, false);
                console.log("Arbitrage executed successfully!");
                console.log("Expected profit:", profitB / 1e18, "TokenA");
            } else {
                // 从Pool A借贷更有利润  
                console.log("\nExecuting arbitrage: borrow from Pool A");
                flashSwap.executeFlashSwap(tokenA, tokenB, testAmount, true);
                console.log("Arbitrage executed successfully!");
                console.log("Expected profit:", profitA / 1e18, "TokenA");
            }
        } else {
            console.log("No arbitrage opportunity found!");
        }

        vm.stopBroadcast();
    }
} 