// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC721_Upgrade} from "../src/ERC721_Upgrade.sol";
import {UUPSUpgradeable} from "@openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract DeployUpgradeERC721 is Script {
    function run() public {
        // 获取部署者的私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // 部署实现合约
        ERC721_Upgrade implementation = new ERC721_Upgrade();
        console.log("ERC721_Upgrade Implementation deployed to:", address(implementation));

        // 部署 ProxyAdmin (可选，但推荐用于管理多个代理)
        // ProxyAdmin proxyAdmin = new ProxyAdmin();
        // console.log("ProxyAdmin deployed to:", address(proxyAdmin));

        // 准备初始化数据
        string memory name = "MyUpgradeableNFT";
        string memory symbol = "MUN";
        bytes memory initializeData = abi.encodeWithSelector(
            ERC721_Upgrade.initialize.selector,
            name,
            symbol
        );

        // 部署 TransparentUpgradeableProxy
        // 注意：这里直接使用 deployer 作为 admin，如果需要 ProxyAdmin，请修改
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(implementation),
            deployer, // Admin address (deployer or ProxyAdmin address)
            initializeData
        );
        console.log("TransparentUpgradeableProxy deployed to:", address(proxy));

        // 获取代理合约的接口
        ERC721_Upgrade upgradeableNFT = ERC721_Upgrade(address(proxy));
        console.log("Upgradeable NFT (via proxy) address:", address(upgradeableNFT));

        vm.stopBroadcast();
    }
}