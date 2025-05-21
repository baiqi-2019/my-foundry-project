// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NFTMarketV2.sol";

contract ManualUpgrade is Script {
    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS"); // 从环境变量获取代理地址
        uint256 ownerPrivateKey = vm.envUint("PRIVATE_KEY"); // 从环境变量获取owner私钥
        
        // 使用owner的私钥进行广播
        vm.startBroadcast(ownerPrivateKey);
        
        // 1. 部署新的V2实现合约
        NFTMarketV2 marketV2 = new NFTMarketV2();
        console.log("NFTMarketV2 Implementation deployed at:", address(marketV2));
        
        // 2. 直接构造升级调用数据并发送
        bytes memory upgradeCall = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)", 
            address(marketV2), 
            new bytes(0)
        );
        
        // 发送升级交易
        (bool success, ) = proxyAddress.call(upgradeCall);
        require(success, "Upgrade transaction failed");
        
        console.log("NFTMarket Proxy upgraded to V2");
        
        vm.stopBroadcast();
    }
} 