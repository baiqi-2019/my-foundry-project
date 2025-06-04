// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/NFT_Market.sol";
import "../src/MockERC20.sol";
import "../src/MockERC721.sol";

/**
 * @title NFT市场操作脚本
 * @dev 用于执行NFT市场上的各种操作，如上架和购买NFT
 */
contract NFTMarketOperations is Script {
    // 合约地址，需要在调用前通过环境变量设置
    address paymentTokenAddress;
    address nftMarketAddress;
    address mockNFTAddress;
    
    // NFT ID，需要在调用前通过环境变量设置
    uint256 tokenId;
    
    function setUp() public {
        // 从环境变量获取合约地址
        paymentTokenAddress = vm.envAddress("PAYMENT_TOKEN_ADDRESS");
        nftMarketAddress = vm.envAddress("NFT_MARKET_ADDRESS");
        mockNFTAddress = vm.envAddress("MOCK_NFT_ADDRESS");
        
        // 尝试从环境变量获取代币ID，如果未设置则默认为1
        try vm.envUint("TOKEN_ID") returns (uint256 id) {
            tokenId = id;
        } catch {
            tokenId = 1;
        }
    }
    
    /**
     * @dev 上架NFT
     * @param price NFT的价格
     */
    function listNFT(uint256 price) public {
        // 从环境变量获取私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 获取合约实例
        MockERC721 mockNFT = MockERC721(mockNFTAddress);
        NFTMarket nftMarket = NFTMarket(nftMarketAddress);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 检查NFT所有权
        address owner = mockNFT.ownerOf(tokenId);
        console.log("NFT Owner:", owner);
        console.log("Caller:", msg.sender);
        
        // 授权NFT市场操作NFT
        mockNFT.approve(nftMarketAddress, tokenId);
        console.log("Approved NFT Market to handle NFT");
        
        // 上架NFT
        uint256 listingId = nftMarket.list(mockNFTAddress, tokenId, price);
        console.log("NFT Listed with listing ID:", listingId);
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev 购买NFT
     * @param listingId 上架ID
     */
    function buyNFT(uint256 listingId) public {
        // 从环境变量获取私钥
        uint256 buyerPrivateKey = vm.envUint("BUYER_PRIVATE_KEY");
        
        // 获取合约实例
        MockERC20 paymentToken = MockERC20(paymentTokenAddress);
        NFTMarket nftMarket = NFTMarket(nftMarketAddress);
        
        vm.startBroadcast(buyerPrivateKey);
        
        // 获取上架信息
        (address seller, address nftContract, uint256 nftId, uint256 price, bool isActive) = nftMarket.listings(listingId);
        require(isActive, "Listing is not active");
        
        console.log("NFT Listing Info:");
        console.log("Seller:", seller);
        console.log("NFT Contract:", nftContract);
        console.log("NFT ID:", nftId);
        console.log("Price:", price);
        console.log("Is Active:", isActive);
        
        // 检查和授权代币
        uint256 buyerBalance = paymentToken.balanceOf(msg.sender);
        console.log("Buyer Balance:", buyerBalance);
        
        if (buyerBalance < price) {
            // 如果是模拟代币，为买家铸造足够的代币
            paymentToken.mint(msg.sender, price);
            console.log("Minted tokens for buyer");
        }
        
        // 授权NFT市场合约使用代币
        paymentToken.approve(nftMarketAddress, price);
        console.log("Approved tokens for NFT Market");
        
        // 购买NFT
        nftMarket.buyNFT(listingId);
        console.log("NFT purchased successfully");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev 使用回调方式购买NFT
     * @param listingId 上架ID
     */
    function buyNFTWithCallback(uint256 listingId) public {
        // 从环境变量获取私钥
        uint256 buyerPrivateKey = vm.envUint("BUYER_PRIVATE_KEY");
        
        // 获取合约实例
        MockERC20 paymentToken = MockERC20(paymentTokenAddress);
        NFTMarket nftMarket = NFTMarket(nftMarketAddress);
        
        vm.startBroadcast(buyerPrivateKey);
        
        // 获取上架信息
        (address seller, address nftContract, uint256 nftId, uint256 price, bool isActive) = nftMarket.listings(listingId);
        require(isActive, "Listing is not active");
        
        // 检查和授权代币
        uint256 buyerBalance = paymentToken.balanceOf(msg.sender);
        
        if (buyerBalance < price) {
            // 如果是模拟代币，为买家铸造足够的代币
            paymentToken.mint(msg.sender, price);
        }
        
        // 授权NFT市场合约使用代币
        paymentToken.approve(nftMarketAddress, price);
        
        // 使用回调方式购买NFT
        nftMarket.buyNFTWithCallback(listingId);
        console.log("NFT purchased with callback successfully");
        
        vm.stopBroadcast();
    }
    
    /**
     * @dev 运行上架操作
     */
    function runList() external {
        setUp();
        // 上架NFT，价格为100个代币
        listNFT(100 * 10**18);
    }
    
    /**
     * @dev 运行购买操作
     */
    function runBuy() external {
        setUp();
        // 购买上架ID为0的NFT
        buyNFT(0);
    }
    
    /**
     * @dev 运行使用回调购买操作
     */
    function runBuyWithCallback() external {
        setUp();
        // 使用回调购买上架ID为0的NFT
        buyNFTWithCallback(0);
    }
} 