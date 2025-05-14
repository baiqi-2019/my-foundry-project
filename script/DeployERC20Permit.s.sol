// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/ERC20_Permit.sol";

contract DeployERC20Permit is Script {
    function run() external {
        // 开始广播交易
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署ERC20Permit合约
        ERC20Permit token = new ERC20Permit();
        
        vm.stopBroadcast();
        
        // 输出部署的合约地址
        console.log("ERC20Permit deployed at:", address(token));
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        console.log("Total supply:", token.totalSupply());
    }
}