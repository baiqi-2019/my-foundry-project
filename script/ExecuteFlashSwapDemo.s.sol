// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwap.sol";

contract ExecuteFlashSwapDemo is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 获取部署的合约地址
        address flashSwapAddress = vm.envAddress("FLASH_SWAP_ADDRESS");
        address poolAddress = vm.envAddress("POOL_A_ADDRESS");
        address tokenAAddress = vm.envAddress("TOKEN_A_ADDRESS");
        address tokenBAddress = vm.envAddress("TOKEN_B_ADDRESS");

        FlashSwap flashSwap = FlashSwap(flashSwapAddress);

        console.log("=== Flash Swap Demo Execution ===");
        console.log("FlashSwap Contract:", flashSwapAddress);
        console.log("Pool Address:", poolAddress);
        console.log("Token A:", tokenAAddress);
        console.log("Token B:", tokenBAddress);
        console.log("Deployer:", msg.sender);
        console.log("FlashSwap Owner:", flashSwap.owner());

        // 执行闪电兑换演示
        // 注意：这里我们使用同一个池子作为 poolA 和 poolB 来演示流程
        // 在真实套利中，这两个应该是不同的池子
        uint256 amountToBorrow = 100 * 1e18; // 借贷 100 个 TokenA
        
        console.log("\nExecuting flash swap...");
        console.log("Amount to borrow:", amountToBorrow);

        try flashSwap.executeFlashSwap(
            poolAddress,     // poolA (借贷池)
            poolAddress,     // poolB (交易池，演示中使用同一个池)
            tokenAAddress,   // 借贷的代币
            tokenBAddress,   // 交换的目标代币
            amountToBorrow
        ) {
            console.log("Flash swap executed successfully!");
            console.log("Check transaction logs for FlashSwapExecuted event");
        } catch Error(string memory reason) {
            console.log("Flash swap failed with reason:", reason);
        } catch {
            console.log("Flash swap failed with unknown error");
        }

        vm.stopBroadcast();
    }
} 