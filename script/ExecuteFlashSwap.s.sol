// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/FlashSwap.sol";

contract ExecuteFlashSwap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 这些地址需要替换为实际部署的合约地址
        address flashSwapAddress = vm.envAddress("FLASH_SWAP_ADDRESS");
        address poolAAddress = vm.envAddress("POOL_A_ADDRESS");
        address poolBAddress = vm.envAddress("POOL_B_ADDRESS"); // 注意：在真实场景中需要两个不同的池子
        address tokenAAddress = vm.envAddress("TOKEN_A_ADDRESS");
        address tokenBAddress = vm.envAddress("TOKEN_B_ADDRESS");

        FlashSwap flashSwap = FlashSwap(flashSwapAddress);

        // 执行闪电兑换
        uint256 amountToBorrow = 1000 * 1e18; // 借贷 1000 个 TokenA
        
        console.log("Executing flash swap...");
        console.log("Pool A:", poolAAddress);
        console.log("Pool B:", poolBAddress);
        console.log("Token A:", tokenAAddress);
        console.log("Token B:", tokenBAddress);
        console.log("Amount to borrow:", amountToBorrow);

        flashSwap.executeFlashSwap(
            poolAAddress,
            poolBAddress,
            tokenAAddress,
            tokenBAddress,
            amountToBorrow
        );

        console.log("Flash swap executed successfully!");

        vm.stopBroadcast();
    }
} 