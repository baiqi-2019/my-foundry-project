// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/MockERC721.sol";

/**
 * @title 单独部署MockERC721脚本
 * @dev 用于重新部署修复后的MockERC721合约
 */
contract DeployMockERC721Only is Script {
    function run() external {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始广播交易
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署修复后的模拟ERC721 NFT合约
        MockERC721 mockNFT = new MockERC721("Mock NFT", "MNFT");
        console.log("New MockERC721 deployed at:", address(mockNFT));
        
        // 铸造NFT给部署者
        uint256 tokenId = mockNFT.mint(msg.sender);
        console.log("Minted NFT with ID:", tokenId);
        
        // 结束广播
        vm.stopBroadcast();
        
        console.log("");
        console.log("Please update MOCK_NFT_ADDRESS in your .env file to:");
        console.log("MOCK_NFT_ADDRESS=", address(mockNFT));
    }
} 