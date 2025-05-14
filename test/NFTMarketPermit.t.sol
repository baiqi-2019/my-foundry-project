// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFT_Market_Permit.sol";

// 模拟ERC20代币合约
contract MockERC20 is IExtendedERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    string public name = "Mock Token";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * 10**18;
    
    constructor() {
        _balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
        _allowances[sender][msg.sender] -= amount;
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
    }
    
    function transferWithCallback(address _to, uint256 _value) external override returns (bool) {
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        ITokenReceiver(_to).tokensReceived(msg.sender, _value, "");
        return true;
    }
    
    function transferWithCallbackAndData(address _to, uint256 _value, bytes calldata _data) external override returns (bool) {
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        ITokenReceiver(_to).tokensReceived(msg.sender, _value, _data);
        return true;
    }
}

// 模拟ERC721代币合约
contract MockERC721 is IERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;
    string public name = "MyNFT";
    string public symbol = "MNFT";
    
    function mint(address to, uint256 tokenId) external {
        _owners[tokenId] = to;
    }
    
    function ownerOf(uint256 tokenId) external view override returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: owner query for nonexistent token");
        return _owners[tokenId];
    }
    
    function transferFrom(address /*from*/, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _owners[tokenId] = to;
    }
    
    function safeTransferFrom(address /*from*/, address to, uint256 tokenId) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _owners[tokenId] = to;
    }
    
    function approve(address to, uint256 tokenId) external {
        address owner = _owners[tokenId];
        require(msg.sender == owner || _operatorApprovals[owner][msg.sender], "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[tokenId] = to;
    }
    
    function getApproved(uint256 tokenId) external view override returns (address) {
        return _tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) external {
        _operatorApprovals[msg.sender][operator] = approved;
    }
    
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _owners[tokenId];
        return (spender == owner || 
                _operatorApprovals[owner][spender] || 
                _tokenApprovals[tokenId] == spender);
    }
}

contract NFTMarketPermitTest is Test {
    NFTMarket public market;
    MockERC20 public paymentToken;
    MockERC721 public nftContract;
    
    address public seller = address(1);
    address public buyer = address(2);
    address public projectSigner = address(3);
    
    uint256 public tokenId = 1;
    uint256 public price = 100 * 10**18; // 100 tokens
    uint256 public signerPrivateKey = 0xA11CE; // 项目方签名者私钥
    
    function setUp() public {
        // 设置项目方签名者私钥
        projectSigner = vm.addr(signerPrivateKey);
        vm.deal(projectSigner, 100 ether);
        
        // 部署模拟代币合约
        paymentToken = new MockERC20();
        nftContract = new MockERC721();
        
        // 部署NFT市场合约，使用项目方签名者地址
        market = new NFTMarket(address(paymentToken), projectSigner);
        
        // 为测试账户铸造NFT和代币
        nftContract.mint(seller, tokenId);
        paymentToken.mint(buyer, 1000 * 10**18);
        
        // 设置测试账户标签
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(projectSigner, "Project Signer");
        vm.label(address(market), "NFTMarket");
        vm.label(address(paymentToken), "Payment Token");
        vm.label(address(nftContract), "NFT Contract");
    }
    
    // 测试白名单购买NFT成功的情况
    function testPermitBuySuccess() public {
        console.log("Starting permitBuy test with whitelisted buyer");
        
        // 卖家上架NFT
        vm.startPrank(seller);
        console.log("Seller listing NFT with ID:", tokenId);
        uint256 listingId = market.list(address(nftContract), tokenId, price);
        console.log("NFT listed with listing ID:", listingId);
        
        // 卖家授权市场合约转移NFT
        nftContract.approve(address(market), tokenId);
        console.log("Seller approved market contract to transfer NFT");
        vm.stopPrank();
        
        // 准备签名数据
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = market.nonces(buyer);
        
        // 计算要签名的消息
        bytes32 domainSeparator = keccak256(
            abi.encode(
                market.DOMAIN_TYPEHASH(),
                keccak256(bytes(market.DOMAIN_NAME())),
                keccak256(bytes(market.DOMAIN_VERSION())),
                block.chainid,
                address(market)
            )
        );
        
        bytes32 structHash = keccak256(
            abi.encode(
                market.WHITELIST_TYPEHASH(),
                buyer,
                listingId,
                nonce,
                deadline
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        
        console.log("Generated signature digest for buyer:", buyer);
        
        // 使用项目方签名者的私钥签名消息
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        console.log("Signature created by project signer");
        
        // 买家授权市场合约转移代币
        vm.startPrank(buyer);
        paymentToken.approve(address(market), price);
        console.log("Buyer approved market contract to transfer tokens");
        
        // 记录买家和卖家的初始余额
        uint256 initialSellerBalance = paymentToken.balanceOf(seller);
        uint256 initialBuyerBalance = paymentToken.balanceOf(buyer);
        address initialNFTOwner = nftContract.ownerOf(tokenId);
        
        console.log("Initial NFT owner:", initialNFTOwner);
        console.log("Initial seller token balance:", initialSellerBalance);
        console.log("Initial buyer token balance:", initialBuyerBalance);
        
        // 预期会发出NFTSold事件
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTSold(listingId, buyer, seller, address(nftContract), tokenId, price);
        
        // 买家使用签名购买NFT
        console.log("Buyer executing permitBuy with signature");
        market.permitBuy(listingId, deadline, v, r, s);
        
        // 验证NFT所有权已转移
        address newNFTOwner = nftContract.ownerOf(tokenId);
        assertEq(newNFTOwner, buyer, "NFT ownership should be transferred to buyer");
        console.log("NFT ownership transferred to buyer:", newNFTOwner);
        
        // 验证代币已转移
        uint256 finalSellerBalance = paymentToken.balanceOf(seller);
        uint256 finalBuyerBalance = paymentToken.balanceOf(buyer);
        assertEq(finalSellerBalance, initialSellerBalance + price, "Payment should be transferred to seller");
        assertEq(finalBuyerBalance, initialBuyerBalance - price, "Payment should be deducted from buyer");
        console.log("Final seller token balance:", finalSellerBalance);
        console.log("Final buyer token balance:", finalBuyerBalance);
        
        // 验证上架信息已更新为非活跃
        (, , , , bool isActive) = market.listings(listingId);
        assertFalse(isActive, "Listing should be inactive after purchase");
        console.log("Listing marked as inactive");
        
        console.log("PermitBuy test completed successfully");
        vm.stopPrank();
    }
    
    // 测试非白名单用户购买NFT失败的情况
    function testPermitBuyUnauthorized() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        uint256 listingId = market.list(address(nftContract), tokenId, price);
        nftContract.approve(address(market), tokenId);
        vm.stopPrank();
        
        // 准备签名数据
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = market.nonces(buyer);
        
        // 计算要签名的消息
        bytes32 domainSeparator = keccak256(
            abi.encode(
                market.DOMAIN_TYPEHASH(),
                keccak256(bytes(market.DOMAIN_NAME())),
                keccak256(bytes(market.DOMAIN_VERSION())),
                block.chainid,
                address(market)
            )
        );
        
        bytes32 structHash = keccak256(
            abi.encode(
                market.WHITELIST_TYPEHASH(),
                buyer,
                listingId,
                nonce,
                deadline
            )
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        
        // 使用错误的私钥签名消息
        uint256 wrongPrivateKey = 0xB0B; // 不是项目方签名者的私钥
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPrivateKey, digest);
        
        // 买家授权市场合约转移代币
        vm.startPrank(buyer);
        paymentToken.approve(address(market), price);
        
        // 尝试使用错误签名购买NFT，预期会失败
        vm.expectRevert("NFTMarket: unauthorized buyer");
        market.permitBuy(listingId, deadline, v, r, s);
        
        vm.stopPrank();
    }
}