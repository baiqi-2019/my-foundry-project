// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/OpenspaceNFT.sol";

contract DeployOpenspaceNFT is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署OpenspaceNFT合约
        OpenspaceNFT nft = new OpenspaceNFT();
        
        console.log("OpenspaceNFT deployed to:", address(nft));
        console.log("Owner:", nft.owner());
        console.log("Presale active:", nft.isPresaleActive());
        
        vm.stopBroadcast();
        
        // 输出环境变量更新信息
        console.log("OPENSPACE_NFT_ADDRESS=%s", address(nft));
    }
} 