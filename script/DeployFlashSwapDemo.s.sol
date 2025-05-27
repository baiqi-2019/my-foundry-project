// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwapDemo.sol";

contract DeployFlashSwapDemo is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署演示版闪电兑换合约
        FlashSwapDemo flashSwapDemo = new FlashSwapDemo();
        console.log("FlashSwapDemo deployed at:", address(flashSwapDemo));

        vm.stopBroadcast();
    }
} 