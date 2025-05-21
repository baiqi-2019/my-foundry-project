// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import "../src/NFTMarketV1.sol";
import "../src/NFTMarketV2.sol";
import "../src/NFTMarketProxy.sol";

contract DeployNFTMarket is Script {
    function run() public {
        vm.startBroadcast();
        
        // 部署NFTMarketV1实现
        NFTMarketV1 marketV1 = new NFTMarketV1();
        
        // 准备初始化数据
        address paymentTokenAddress = vm.envAddress("PAYMENT_TOKEN_ADDRESS"); // 从环境变量获取支付代币地址
        bytes memory data = abi.encodeCall(NFTMarketV1.initialize, (paymentTokenAddress));
        
        // 部署代理合约，指向V1实现并初始化
        NFTMarketProxy proxy = new NFTMarketProxy(address(marketV1), data);
        
        console.log("NFTMarketV1 Implementation deployed at:", address(marketV1));
        console.log("NFTMarket Proxy deployed at:", address(proxy));
        
        vm.stopBroadcast();
    }
}

contract UpgradeNFTMarket is Script {
    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS"); // 从环境变量获取代理地址
        
        vm.startBroadcast();
        
        // 部署NFTMarketV2实现
        NFTMarketV2 marketV2 = new NFTMarketV2();
        
        // 使用OpenZeppelin Upgrades库进行升级
        bytes memory data = new bytes(0); // 空数据，因为我们不需要在升级时调用函数
        Upgrades.upgradeProxy(proxyAddress, "NFTMarketV2.sol", data);
        
        console.log("NFTMarketV2 Implementation deployed at:", address(marketV2));
        console.log("NFTMarket Proxy upgraded to V2");
        
        vm.stopBroadcast();
    }
}