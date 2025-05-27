// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwapComplete.sol";

contract DeployFlashSwapComplete is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 从环境变量获取 Uniswap 系统地址
        address factoryA = vm.envAddress("FACTORY_A_ADDRESS");
        address factoryB = vm.envAddress("FACTORY_B_ADDRESS");
        address routerA = vm.envAddress("ROUTER_A_ADDRESS");
        address routerB = vm.envAddress("ROUTER_B_ADDRESS");

        console.log("=== Deploy FlashSwapComplete Contract ===");
        console.log("Factory A:", factoryA);
        console.log("Factory B:", factoryB);
        console.log("Router A:", routerA);
        console.log("Router B:", routerB);

        // 部署闪电兑换合约
        FlashSwapComplete flashSwap = new FlashSwapComplete(
            factoryA,
            factoryB,
            routerA,
            routerB
        );

        console.log("FlashSwapComplete deployed at:", address(flashSwap));
        console.log("Owner:", flashSwap.owner());

        console.log("\nUpdate environment variables:");
        console.log("FLASH_SWAP_COMPLETE_ADDRESS=", address(flashSwap));

        vm.stopBroadcast();
    }
} 