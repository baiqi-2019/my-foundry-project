// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwapComplete.sol";

contract ExecuteFlashSwapComplete is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 获取合约地址
        address flashSwapAddress = vm.envAddress("FLASH_SWAP_COMPLETE_ADDRESS");
        address tokenAAddress = vm.envAddress("TOKEN_A_ADDRESS");
        address tokenBAddress = vm.envAddress("TOKEN_B_ADDRESS");

        FlashSwapComplete flashSwap = FlashSwapComplete(flashSwapAddress);

        console.log("=== Execute Flash Swap Arbitrage ===");
        console.log("FlashSwap Contract:", flashSwapAddress);
        console.log("Token A:", tokenAAddress);
        console.log("Token B:", tokenBAddress);
        console.log("Owner:", flashSwap.owner());

        // 检查套利机会
        uint256 testAmount = 1000 * 1e18; // 测试 1000 个 TokenA
        
        console.log("\nChecking arbitrage opportunities...");
        console.log("Test amount:", testAmount);
        
        (bool profitable, uint256 profitA, uint256 profitB) = flashSwap.checkArbitrageOpportunity(
            tokenAAddress,
            tokenBAddress,
            testAmount
        );
        
        console.log("Profitable:", profitable);
        console.log("Profit from borrowing A:", profitA);
        console.log("Profit from borrowing B:", profitB);
        
        if (!profitable) {
            console.log("No arbitrage opportunity found!");
            vm.stopBroadcast();
            return;
        }
        
        // 选择最优策略
        bool borrowFromA = profitA >= profitB;
        uint256 expectedProfit = borrowFromA ? profitA : profitB;
        
        console.log("\nExecuting flash swap...");
        console.log("Strategy: Borrow from", borrowFromA ? "System A" : "System B");
        console.log("Expected profit:", expectedProfit);
        
        try flashSwap.executeFlashSwap(
            tokenAAddress,
            tokenBAddress,
            testAmount,
            borrowFromA
        ) {
            console.log("Flash swap executed successfully!");
            console.log("Check transaction logs for FlashSwapExecuted event");
        } catch Error(string memory reason) {
            console.log("Flash swap failed:", reason);
        } catch {
            console.log("Flash swap failed with unknown error");
        }

        vm.stopBroadcast();
    }
} 