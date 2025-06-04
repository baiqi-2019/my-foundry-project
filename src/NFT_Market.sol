// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces.sol";

/**
 * @title NFT市场合约
 * @dev 实现NFT的上架、购买和取消上架功能
 */
contract NFTMarket is ITokenReceiver {
    IExtendedERC20 public immutable paymentToken;    // 支付代币合约

    /**
     * @dev NFT上架信息结构
     */
    struct Listing {
        address seller;          // 卖家地址
        address nftContract;     // NFT合约地址
        uint256 tokenId;         // NFT的Token ID
        uint256 price;           // 价格
        bool isActive;           // 是否处于活跃状态
    }

    mapping(uint256 => Listing) public listings;    // 上架信息映射
    uint256 public nextListingId;    // 下一个上架ID

    // 事件定义
    event NFTListed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);    // NFT上架事件
    event NFTSold(uint256 indexed listingId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 price);    // NFT售出事件
    event NFTListingCancelled(uint256 indexed listingId);    // NFT取消上架事件

    /**
     * @dev 构造函数
     * @param _paymentTokenAddress 支付代币合约地址
     */
    constructor(address _paymentTokenAddress) {
        require(_paymentTokenAddress != address(0), "NFTMarket: payment token address cannot be zero");
        paymentToken = IExtendedERC20(_paymentTokenAddress);
    }

    /**
     * @dev 上架NFT
     * @param _nftContract NFT合约地址
     * @param _tokenId NFT的Token ID
     * @param _price 价格
     * @return 上架ID
     */
    function list(address _nftContract, uint256 _tokenId, uint256 _price) external returns (uint256) {
        require(_price > 0, "NFTMarket: price must be greater than zero");
        require(_nftContract != address(0), "NFTMarket: NFT contract address cannot be zero");

        IERC721 nftContract = IERC721(_nftContract);
        address owner = nftContract.ownerOf(_tokenId);
        require(
            owner == msg.sender || 
            nftContract.isApprovedForAll(owner, msg.sender) || 
            nftContract.getApproved(_tokenId) == msg.sender,
            "NFTMarket: caller is not owner nor approved"
        );

        uint256 listingId = nextListingId++;
        listings[listingId] = Listing({
            seller: owner,
            nftContract: _nftContract,
            tokenId: _tokenId,
            price: _price,
            isActive: true
        });

        emit NFTListed(listingId, owner, _nftContract, _tokenId, _price);
        return listingId;
    }

    /**
     * @dev 取消上架NFT
     * @param _listingId 上架ID
     */
    function cancelListing(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "NFTMarket: listing is not active");
        require(listing.seller == msg.sender, "NFTMarket: caller is not the seller");

        listing.isActive = false;
        emit NFTListingCancelled(_listingId);
    }

    /**
     * @dev 购买NFT
     * @param _listingId 上架ID
     */
    function buyNFT(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "NFTMarket: listing is not active");
        require(paymentToken.balanceOf(msg.sender) >= listing.price, "NFTMarket: insufficient token balance");

        listing.isActive = false;

        require(paymentToken.transferFrom(msg.sender, listing.seller, listing.price), "NFTMarket: token transfer failed");
        IERC721(listing.nftContract).transferFrom(listing.seller, msg.sender, listing.tokenId);

        emit NFTSold(_listingId, msg.sender, listing.seller, listing.nftContract, listing.tokenId, listing.price);
    }

    /**
     * @dev 接收代币并处理NFT购买逻辑
     * @param from 代币发送者
     * @param amount 代币数量
     * @param data 附带数据
     * @return 处理成功返回true
     */
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override returns (bool) {
        require(msg.sender == address(paymentToken), "NFTMarket: caller is not the payment token contract");
        require(data.length == 32, "NFTMarket: invalid data length");

        uint256 listingId = abi.decode(data, (uint256));
        Listing storage listing = listings[listingId];

        require(listing.isActive, "NFTMarket: listing is not active");
        require(amount == listing.price, "NFTMarket: incorrect payment amount");

        listing.isActive = false;

        require(paymentToken.transfer(listing.seller, amount), "NFTMarket: token transfer to seller failed");
        IERC721(listing.nftContract).transferFrom(listing.seller, from, listing.tokenId);

        emit NFTSold(listingId, from, listing.seller, listing.nftContract, listing.tokenId, amount);
        return true;
    }

    /**
     * @dev 使用回调功能购买NFT
     * @param _listingId 上架ID
     */
    function buyNFTWithCallback(uint256 _listingId) external {
        Listing storage listing = listings[_listingId];
        require(listing.isActive, "NFTMarket: listing is not active");
        require(paymentToken.balanceOf(msg.sender) >= listing.price, "NFTMarket: insufficient token balance");

        bytes memory data = abi.encode(_listingId);
        require(paymentToken.transferWithCallbackAndData(address(this), listing.price, data), "NFTMarket: token transfer with callback failed");
    }
}
