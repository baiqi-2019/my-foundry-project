// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwapDemo.sol";

contract ExecuteFlashSwapDemoSimple is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 获取部署的合约地址
        address flashSwapDemoAddress = vm.envAddress("FLASH_SWAP_DEMO_ADDRESS");
        address poolAddress = vm.envAddress("POOL_A_ADDRESS");
        address tokenAAddress = vm.envAddress("TOKEN_A_ADDRESS");

        FlashSwapDemo flashSwapDemo = FlashSwapDemo(flashSwapDemoAddress);

        console.log("=== Flash Swap Demo Execution ===");
        console.log("FlashSwapDemo Contract:", flashSwapDemoAddress);
        console.log("Pool Address:", poolAddress);
        console.log("Token A:", tokenAAddress);
        console.log("Deployer:", msg.sender);
        console.log("FlashSwapDemo Owner:", flashSwapDemo.owner());

        // 执行闪电兑换演示
        uint256 amountToBorrow = 10 * 1e18; // 借贷 10 个 TokenA
        
        console.log("\nExecuting flash swap demo...");
        console.log("Amount to borrow:", amountToBorrow);

        try flashSwapDemo.executeFlashSwapDemo(
            poolAddress,     // 池子地址
            tokenAAddress,   // 借贷的代币
            amountToBorrow   // 借贷数量
        ) {
            console.log("Flash swap demo executed successfully!");
            console.log("Check transaction logs for FlashSwapExecuted event");
        } catch Error(string memory reason) {
            console.log("Flash swap demo failed with reason:", reason);
        } catch {
            console.log("Flash swap demo failed with unknown error");
        }

        vm.stopBroadcast();
    }
} 