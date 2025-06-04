// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import "../src/NFTMarketV1.sol";
import "../src/NFTMarketV2.sol";
import "../src/NFTMarketProxy.sol";
import "../src/NFT_Market.sol";
import "../src/MockERC20.sol"; // 我们需要一个支付代币
import "../src/MockERC721.sol";

/**
 * @title NFTMarket部署脚本
 * @dev 用于部署NFTMarket和相关模拟合约
 */
contract DeployNFTMarket is Script {
    function run() external {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署模拟ERC20代币作为支付代币
        MockERC20 paymentToken = new MockERC20("Payment Token", "PAY", 18);
        console.log("PaymentToken deployed at:", address(paymentToken));
        
        // 部署NFT市场合约
        NFTMarket nftMarket = new NFTMarket(address(paymentToken));
        console.log("NFTMarket deployed at:", address(nftMarket));
        
        // 部署模拟ERC721 NFT合约
        MockERC721 mockNFT = new MockERC721("Mock NFT", "MNFT");
        console.log("MockERC721 deployed at:", address(mockNFT));
        
        // 铸造NFT给部署者
        uint256 tokenId = mockNFT.mint(msg.sender);
        console.log("Minted NFT with ID:", tokenId);
        
        // 结束广播
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