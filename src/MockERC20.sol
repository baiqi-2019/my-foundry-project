// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces.sol";

/**
 * @title 模拟ERC20代币
 * @dev 实现了IExtendedERC20接口的简单ERC20代币，用于测试NFTMarket
 */
contract MockERC20 is IExtendedERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    /**
     * @dev 构造函数
     * @param _name 代币名称
     * @param _symbol 代币符号
     * @param _decimals 小数位数
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        
        // 为部署者铸造一些代币用于测试
        _mint(msg.sender, 1000000 * 10**_decimals);
    }
    
    /**
     * @dev 查询账户余额
     * @param account 账户地址
     * @return 账户余额
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev 转账
     * @param recipient 接收者地址
     * @param amount 金额
     * @return 是否成功
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev 从指定账户转账
     * @param sender 发送者地址
     * @param recipient 接收者地址
     * @param amount 金额
     * @return 是否成功
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "MockERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }
    
    /**
     * @dev 授权
     * @param spender 被授权者地址
     * @param amount 授权金额
     * @return 是否成功
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        return true;
    }
    
    /**
     * @dev 查询授权额度
     * @param owner 所有者地址
     * @param spender 被授权者地址
     * @return 授权金额
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev 带回调的转账
     * @param _to 接收者地址
     * @param _value 金额
     * @return 是否成功
     */
    function transferWithCallback(address _to, uint256 _value) external override returns (bool) {
        _transfer(msg.sender, _to, _value);
        
        // 调用接收者的tokensReceived回调
        if (_isContract(_to)) {
            ITokenReceiver receiver = ITokenReceiver(_to);
            receiver.tokensReceived(msg.sender, _value, "");
        }
        
        return true;
    }
    
    /**
     * @dev 带数据和回调的转账
     * @param _to 接收者地址
     * @param _value 金额
     * @param _data 附带数据
     * @return 是否成功
     */
    function transferWithCallbackAndData(address _to, uint256 _value, bytes calldata _data) external override returns (bool) {
        _transfer(msg.sender, _to, _value);
        
        // 调用接收者的tokensReceived回调
        if (_isContract(_to)) {
            ITokenReceiver receiver = ITokenReceiver(_to);
            receiver.tokensReceived(msg.sender, _value, _data);
        }
        
        return true;
    }
    
    /**
     * @dev 内部转账函数
     * @param sender 发送者地址
     * @param recipient 接收者地址
     * @param amount 金额
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "MockERC20: transfer from the zero address");
        require(recipient != address(0), "MockERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "MockERC20: transfer amount exceeds balance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
    }
    
    /**
     * @dev 内部铸造函数
     * @param account 接收者地址
     * @param amount 金额
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "MockERC20: mint to the zero address");
        
        totalSupply += amount;
        _balances[account] += amount;
    }
    
    /**
     * @dev 铸造代币（用于测试）
     * @param account 接收者地址
     * @param amount 金额
     */
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
    
    /**
     * @dev 检查地址是否为合约
     * @param _addr 要检查的地址
     * @return 是否为合约
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
} 