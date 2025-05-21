// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC721_Upgrade} from "../src/ERC721_Upgrade.sol";
import {ERC721_Upgrade_V2} from "../src/ERC721_Upgrade_V2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OwnableUpgradeable} from "@openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";

contract ERC721UpgradeTest is Test {
    ERC721_Upgrade implementation;
    ERC721_Upgrade_V2 implementationV2;
    ERC1967Proxy proxy;
    ERC721_Upgrade wrappedProxy;
    ERC721_Upgrade_V2 wrappedProxyV2;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        // 部署初始实现合约
        implementation = new ERC721_Upgrade();
        
        // 先将msg.sender设置为owner，这样initialize时会正确设置合约所有者
        vm.startPrank(owner);
        
        // 准备初始化数据
        bytes memory initData = abi.encodeWithSelector(
            ERC721_Upgrade.initialize.selector,
            "TestNFT",
            "TNFT"
        );
        
        // 部署代理合约，指向实现合约，并传入初始化数据
        proxy = new ERC1967Proxy(
            address(implementation),
            initData
        );
        
        // 将代理合约包装为ERC721_Upgrade类型方便调用
        wrappedProxy = ERC721_Upgrade(address(proxy));
        
        // 测试环境的msg.sender已经是owner，不需要再次startPrank
    }

    function testInitialState() public view {
        // 测试初始状态
        assertEq(wrappedProxy.name(), "TestNFT");
        assertEq(wrappedProxy.symbol(), "TNFT");
        assertEq(wrappedProxy.owner(), owner);
    }

    function testMinting() public {
        // 测试铸造功能
        wrappedProxy.mint(user1, 1);
        wrappedProxy.mint(user1, 2);
        wrappedProxy.mint(user2, 3);
        
        assertEq(wrappedProxy.balanceOf(user1), 2);
        assertEq(wrappedProxy.balanceOf(user2), 1);
        assertEq(wrappedProxy.ownerOf(1), user1);
        assertEq(wrappedProxy.ownerOf(2), user1);
        assertEq(wrappedProxy.ownerOf(3), user2);
    }

    function testUpgrade() public {
        // 首先铸造一些NFT
        wrappedProxy.mint(user1, 1);
        wrappedProxy.mint(user1, 2);
        wrappedProxy.mint(user2, 3);
        
        // 记录升级前的状态
        uint256 user1BalanceBefore = wrappedProxy.balanceOf(user1);
        uint256 user2BalanceBefore = wrappedProxy.balanceOf(user2);
        address token1OwnerBefore = wrappedProxy.ownerOf(1);
        address token2OwnerBefore = wrappedProxy.ownerOf(2);
        address token3OwnerBefore = wrappedProxy.ownerOf(3);
        
        // 部署V2实现合约
        implementationV2 = new ERC721_Upgrade_V2();
        
        // 执行升级
        wrappedProxy.upgradeToAndCall(address(implementationV2), "");
        
        // 将代理合约包装为V2类型以访问新功能
        wrappedProxyV2 = ERC721_Upgrade_V2(address(proxy));
        
        // 调用初始化V2的函数
        wrappedProxyV2.initializeV2();
        
        // 验证升级后状态保持一致
        assertEq(wrappedProxyV2.balanceOf(user1), user1BalanceBefore);
        assertEq(wrappedProxyV2.balanceOf(user2), user2BalanceBefore);
        assertEq(wrappedProxyV2.ownerOf(1), token1OwnerBefore);
        assertEq(wrappedProxyV2.ownerOf(2), token2OwnerBefore);
        assertEq(wrappedProxyV2.ownerOf(3), token3OwnerBefore);
        
        // 验证合约名称和符号保持不变
        assertEq(wrappedProxyV2.name(), "TestNFT");
        assertEq(wrappedProxyV2.symbol(), "TNFT");
        
        // 测试V2新增功能
        assertEq(wrappedProxyV2.version(), 2);
        assertEq(wrappedProxyV2.getVersion(), 2);
        
        // 确认升级后仍然可以铸造新的NFT
        wrappedProxyV2.mint(user2, 4);
        assertEq(wrappedProxyV2.balanceOf(user2), user2BalanceBefore + 1);
        assertEq(wrappedProxyV2.ownerOf(4), user2);
    }

    function testUpgradeUnauthorized() public {
        // 测试非所有者无法升级合约
        vm.stopPrank();
        vm.startPrank(user1);
        
        // 部署V2实现合约
        implementationV2 = new ERC721_Upgrade_V2();
        
        // 尝试从非所有者账户升级，应当失败
        // 使用自定义错误类型，而不是字符串错误信息
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user1)
        );
        wrappedProxy.upgradeToAndCall(address(implementationV2), "");
    }
}
