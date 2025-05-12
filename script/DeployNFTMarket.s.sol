// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NFT_Market.sol";

contract DeployNFTMarket is Script {
    function run() external {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // 从环境变量获取支付代币地址
        address paymentTokenAddress = vm.envAddress("TOKEN_ADDRESS");

        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);

        // 部署NFTMarket合约
        NFTMarket nftMarket = new NFTMarket(paymentTokenAddress);

        // 停止广播交易
        vm.stopBroadcast();

        // 输出部署信息
        console.log("NFTMarket deployed at:", address(nftMarket));
        console.log("Using payment token at address:", paymentTokenAddress);
    }
}