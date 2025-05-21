// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NFTMarketV2.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

interface IUUPSProxy {
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;
}

contract UpgradeNFTMarketV2 is Script {
    function run() public {
        address proxyAddress = vm.envAddress("PROXY_ADDRESS"); // 从环境变量获取代理地址
        
        vm.startBroadcast();
        
        // 部署新的V2实现合约
        NFTMarketV2 marketV2 = new NFTMarketV2();
        console.log("NFTMarketV2 Implementation deployed at:", address(marketV2));

        // 使用代理合约的管理员身份调用升级函数
        IUUPSProxy proxy = IUUPSProxy(proxyAddress);
        // 没有需要调用的初始化函数，所以传入空数据
        proxy.upgradeToAndCall(address(marketV2), new bytes(0));
        
        console.log("NFTMarket Proxy upgraded to V2");
        
        vm.stopBroadcast();
    }
} 