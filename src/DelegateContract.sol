// SPDX-License-Identifier: MIT
// EIP-7702 Compatible Delegate Contract
// This contract is designed to be used as temporary code for EOA via EIP-7702

pragma solidity ^0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenBank } from "../src/TokenBank.sol";

/**
 * @title SimpleDelegateContract
 * @notice EIP-7702兼容的委托合约
 * @dev 这个合约被设计为通过EIP-7702作为EOA的临时代码使用
 */
contract SimpleDelegateContract {
    event Executed(address indexed to, uint256 value, bytes data);
    event Log(string message);
 
    struct Call {
        bytes data;
        address to;
        uint256 value;
    }
 
    /**
     * @notice 批量执行调用 - EIP-7702的核心功能
     * @dev 当EOA设置了此合约代码后，可以直接调用此函数执行批量操作
     */
    function execute(Call[] memory calls) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];
            (bool success, bytes memory result) = call.to.call{value: call.value}(call.data);
            require(success, string(result));
            emit Executed(call.to, call.value, call.data);
        }
    }

    /**
     * @notice 初始化函数 - 测试EIP-7702是否工作
     */
    function initialize() external payable {
        emit Log('EIP-7702 Delegate Contract Initialized!');
    }
    
    /**
     * @notice 测试函数
     */
    function ping() external {
        emit Log('Pong from EIP-7702 Delegate!');
    }

    /**
     * @notice 一步完成：授权并存款到TokenBank
     * @dev 这是为EIP-7702优化的函数，EOA可以直接调用
     * @param token ERC20代币地址
     * @param tokenbank TokenBank合约地址  
     * @param amount 存款数量
     */
    function approveAndDeposit(address token, address tokenbank, uint256 amount) external {
        // 当通过EIP-7702调用时，msg.sender就是原始的EOA
        // 所以可以直接授权和存款
        require(IERC20(token).approve(tokenbank, amount), "Approve failed");
        TokenBank(tokenbank).deposit(amount);
        
        emit Log('Approve and Deposit completed via EIP-7702!');
    }

    /**
     * @notice EIP-7702优化版本：批量授权并存款
     * @dev 使用批量执行框架，但更适合EIP-7702场景
     */
    function batchApproveAndDeposit(address token, address tokenbank, uint256 amount) external {
        Call[] memory calls = new Call[](2);
        
        // 第1步：授权TokenBank（这里msg.sender是原始EOA）
        calls[0] = Call({
            to: token,
            data: abi.encodeWithSignature("approve(address,uint256)", tokenbank, amount),
            value: 0
        });
        
        // 第2步：存入TokenBank（这里msg.sender还是原始EOA）
        calls[1] = Call({
            to: tokenbank,
            data: abi.encodeWithSignature("deposit(uint256)", amount),
            value: 0
        });
        
        // 执行批量操作
        this.execute(calls);
    }

    /**
     * @notice 接收ETH
     */
    receive() external payable {}

    /**
     * @notice 回退函数，支持任意调用
     */
    fallback() external payable {}
}
 
contract MockERC20 {
    address public minter;
    mapping(address => uint256) private _balances;
 
    constructor(address _minter) {
        minter = _minter;
    }
 
    function mint(uint256 amount, address to) public {
        _mint(to, amount);
    }
 
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
 
    function _mint(address account, uint256 amount) internal {
        require(msg.sender == minter, "ERC20: msg.sender is not minter");
        require(account != address(0), "ERC20: mint to the zero address");
        unchecked {
            _balances[account] += amount;
        }
    }
}