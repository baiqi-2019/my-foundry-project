// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTMarketV1.sol";
import "../src/NFTMarketV2.sol";
import "../src/NFTMarketProxy.sol";
import "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

// 模拟ERC721
contract MockERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;
    
    function mint(address to, uint256 tokenId) public {
        _owners[tokenId] = to;
    }
    
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
    }
    
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function approve(address to, uint256 tokenId) public {
        _tokenApprovals[tokenId] = to;
    }
    
    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public {
        _owners[tokenId] = to;
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        _owners[tokenId] = to;
    }
}

// 模拟ERC20
contract MockERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    function mint(address to, uint256 amount) public {
        _balances[to] += amount;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
    
    function transferWithCallback(address _to, uint256 _value) public returns (bool) {
        return true;
    }
    
    function transferWithCallbackAndData(address _to, uint256 _value, bytes calldata _data) public returns (bool) {
        return true;
    }
}

contract NFTMarketTest is Test {
    NFTMarketV1 marketV1;
    NFTMarketV2 marketV2;
    NFTMarketProxy proxy;
    MockERC721 mockNFT;
    MockERC20 mockToken;
    
    address seller = address(1);
    address buyer = address(2);
    uint256 tokenId = 1;
    uint256 price = 1 ether;
    
    function setUp() public {
        // 部署模拟合约
        mockNFT = new MockERC721();
        mockToken = new MockERC20();
        
        // 部署NFTMarketV1
        marketV1 = new NFTMarketV1();
        
        // 创建初始化数据
        bytes memory data = abi.encodeCall(NFTMarketV1.initialize, (address(mockToken)));
        
        // 部署代理
        proxy = new NFTMarketProxy(address(marketV1), data);
        
        // 铸造NFT和代币
        mockNFT.mint(seller, tokenId);
        mockToken.mint(buyer, 10 ether);
        
        // 给予卖家授权
        vm.prank(seller);
        mockNFT.setApprovalForAll(address(proxy), true);
        
        // 给予买家授权
        vm.prank(buyer);
        mockToken.approve(address(proxy), 10 ether);
    }
    
    function testListingAndBuyingNFTV1() public {
        NFTMarketV1 proxyAsV1 = NFTMarketV1(address(proxy));
        
        // 上架NFT
        vm.prank(seller);
        uint256 listingId = proxyAsV1.list(address(mockNFT), tokenId, price);
        
        // 验证上架信息
        (address listedSeller, address nftContract, uint256 listedTokenId, uint256 listedPrice, bool isActive) = proxyAsV1.listings(listingId);
        assertEq(listedSeller, seller);
        assertEq(nftContract, address(mockNFT));
        assertEq(listedTokenId, tokenId);
        assertEq(listedPrice, price);
        assertTrue(isActive);
        
        // 购买NFT
        vm.prank(buyer);
        proxyAsV1.buyNFT(listingId);
        
        // 验证购买结果
        assertEq(mockNFT.ownerOf(tokenId), buyer);
        (,,,,isActive) = proxyAsV1.listings(listingId);
        assertFalse(isActive);
    }
    
    function testUpgradeToV2() public {
        // 部署V2实现
        marketV2 = new NFTMarketV2();
        
        // 模拟直接升级，不使用OpenZeppelin库
        // 注意：在setUp中，代理合约已经初始化，并且所有者是当前测试合约
        vm.prank(address(this)); // 使用测试合约的地址作为所有者
        (bool success,) = address(proxy).call(
            abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(marketV2), hex"")
        );
        
        require(success, "Upgrade failed");
        
        // 测试V2新功能 - 签名上架
        NFTMarketV2 proxyAsV2 = NFTMarketV2(address(proxy));
        
        // 铸造新的NFT给seller，方便测试签名功能
        uint256 tokenId2 = 2;
        mockNFT.mint(seller, tokenId2);
        
        // 测试签名上架的准备
        uint256 deadline = block.timestamp + 1 days;
        bytes32 messageHash = proxyAsV2.getListingMessageHash(
            address(mockNFT),
            tokenId2,
            price,
            deadline
        );
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(messageHash);
        
        // 在Forge测试中，vm.addr可以从私钥获取地址
        uint256 sellerPrivateKey = 1; // 我们使用固定的私钥1来表示seller
        address derivedSellerAddress = vm.addr(sellerPrivateKey);
        
        // 重新将NFT所有权设置为派生地址，确保所有者正确
        mockNFT.mint(derivedSellerAddress, tokenId2);
        
        // 给予市场合约授权
        vm.prank(derivedSellerAddress);
        mockNFT.setApprovalForAll(address(proxy), true);
        
        // 模拟签名 - 使用私钥1签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);
        
        // 测试签名上架
        vm.prank(address(3)); // 任何地址都可以调用
        uint256 listingId = proxyAsV2.listWithSignature(
            address(mockNFT),
            tokenId2,
            price,
            deadline,
            signature
        );
        
        // 验证上架信息
        (address listedSeller, address nftContract, uint256 listedTokenId, uint256 listedPrice, bool isActive) = proxyAsV2.listings(listingId);
        assertEq(listedSeller, derivedSellerAddress);
        assertEq(nftContract, address(mockNFT));
        assertEq(listedTokenId, tokenId2);
        assertEq(listedPrice, price);
        assertTrue(isActive);
    }
} 