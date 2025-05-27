// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwapCorrect.sol";

contract DeployFlashSwapCorrect is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address factoryA = vm.envAddress("FACTORY_A_ADDRESS");
        address factoryB = vm.envAddress("FACTORY_B_ADDRESS");
        address routerA = vm.envAddress("ROUTER_A_ADDRESS");
        address routerB = vm.envAddress("ROUTER_B_ADDRESS");

        console.log("=== Deploy FlashSwap Correct Contract ===");
        console.log("Factory A:", factoryA);
        console.log("Factory B:", factoryB);
        console.log("Router A:", routerA);
        console.log("Router B:", routerB);

        FlashSwapCorrect flashSwap = new FlashSwapCorrect(
            factoryA,
            factoryB,
            routerA,
            routerB
        );

        console.log("FlashSwap Correct deployed at:", address(flashSwap));

        vm.stopBroadcast();
    }
} 