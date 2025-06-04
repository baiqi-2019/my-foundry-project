// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces.sol";

/**
 * @title 模拟ERC721 NFT合约
 * @dev 实现了IERC721接口的简单NFT合约，用于测试NFTMarket
 */
contract MockERC721 {
    string public name;
    string public symbol;
    
    // 代币ID到所有者地址的映射
    mapping(uint256 => address) private _owners;
    
    // 所有者地址到其拥有的代币数量的映射
    mapping(address => uint256) private _balances;
    
    // 代币ID到被授权地址的映射
    mapping(uint256 => address) private _tokenApprovals;
    
    // 所有者地址到操作者地址的授权映射
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // 记录下一个要铸造的代币ID
    uint256 private _nextTokenId = 1;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    /**
     * @dev 构造函数
     * @param _name NFT名称
     * @param _symbol NFT符号
     */
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    /**
     * @dev 返回所有者拥有的NFT数量
     * @param owner 所有者地址
     * @return 拥有的NFT数量
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "MockERC721: balance query for the zero address");
        return _balances[owner];
    }
    
    /**
     * @dev 返回代币ID的所有者
     * @param tokenId 代币ID
     * @return 所有者地址
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "MockERC721: owner query for nonexistent token");
        return owner;
    }
    
    /**
     * @dev 授权另一个地址管理指定的代币
     * @param to 被授权的地址
     * @param tokenId 代币ID
     */
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "MockERC721: approve caller is not owner nor approved for all"
        );
        
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    /**
     * @dev 返回代币的授权地址
     * @param tokenId 代币ID
     * @return 授权地址
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "MockERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    
    /**
     * @dev 设置或取消操作者的授权
     * @param operator 操作者地址
     * @param approved 是否授权
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "MockERC721: approve to caller");
        
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /**
     * @dev 检查操作者是否有所有者所有代币的授权
     * @param owner 所有者地址
     * @param operator 操作者地址
     * @return 是否有授权
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    
    /**
     * @dev 转移代币
     * @param from 当前所有者地址
     * @param to 新所有者地址
     * @param tokenId 代币ID
     */
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "MockERC721: transfer caller is not owner nor approved");
        
        _transfer(from, to, tokenId);
    }
    
    /**
     * @dev 安全转移代币
     * @param from 当前所有者地址
     * @param to 新所有者地址
     * @param tokenId 代币ID
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);
        
        // 这里简化了ERC721标准的安全转移逻辑
        require(
            to.code.length == 0 || 
            _checkOnERC721Received(from, to, tokenId, ""),
            "MockERC721: transfer to non ERC721Receiver implementer"
        );
    }
    
    /**
     * @dev 铸造新NFT
     * @param to 接收者地址
     * @return 铸造的代币ID
     */
    function mint(address to) public returns (uint256) {
        require(to != address(0), "MockERC721: mint to the zero address");
        
        uint256 tokenId = _nextTokenId++;
        _mint(to, tokenId);
        
        return tokenId;
    }
    
    /**
     * @dev 内部铸造函数
     * @param to 接收者地址
     * @param tokenId 代币ID
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "MockERC721: mint to the zero address");
        require(!_exists(tokenId), "MockERC721: token already minted");
        
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(address(0), to, tokenId);
    }
    
    /**
     * @dev 内部转移函数
     * @param from 当前所有者地址
     * @param to 新所有者地址
     * @param tokenId 代币ID
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "MockERC721: transfer of token that is not own");
        require(to != address(0), "MockERC721: transfer to the zero address");
        
        // 清除授权
        _tokenApprovals[tokenId] = address(0);
        
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @dev 检查代币是否存在
     * @param tokenId 代币ID
     * @return 是否存在
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
    
    /**
     * @dev 检查地址是否是代币的所有者或被授权者
     * @param spender 要检查的地址
     * @param tokenId 代币ID
     * @return 是否有权限
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "MockERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    
    /**
     * @dev 检查接收者是否实现了ERC721Receiver接口
     * @param from 发送者地址
     * @param to 接收者地址
     * @param tokenId 代币ID
     * @param data 附加数据
     * @return 是否实现了接口
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        // 这里简化了实现，实际应调用接收者的onERC721Received函数
        // 由于这是一个模拟合约，我们直接返回true
        return true;
    }
} 