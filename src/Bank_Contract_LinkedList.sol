// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bank {
    address public admin;
    mapping(address => uint) public deposits;
    
    // 链表节点结构
    struct Node {
        address user;
        uint amount;
        uint next; // 下一个节点的索引
    }
    
    // 链表存储
    Node[] public topDepositors;
    uint public constant MAX_TOP_USERS = 10; // 最多保存前10名
    uint public head; // 链表头部索引
    uint public size; // 当前链表大小
    
    // 用户在链表中的位置映射
    mapping(address => uint) public userIndex; // 0表示不在链表中，其他值表示在topDepositors中的索引+1
    
    // 事件
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event Deposit(address indexed user, uint amount);
    event Withdraw(uint amount);
    
    constructor() {
        admin = msg.sender;
        
        // 初始化链表，添加一个哨兵节点
        topDepositors.push(Node(address(0), 0, 0));
        head = 0;
        size = 0;
    }
    
    // 设置新管理员，只有当前管理员可以调用
    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "Only admin can set new admin");
        require(newAdmin != address(0), "New admin cannot be zero address");
        
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }
    
    // 接收ETH并记录存款
    receive() external payable {
        _handleDeposit();
    }
    
    // 存款函数，允许用户显式调用存款
    function deposit() external payable {
        _handleDeposit();
    }
    
    function _handleDeposit() internal {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户存款金额
        deposits[msg.sender] += msg.value;
        
        // 更新排行榜
        updateTopDepositors(msg.sender, deposits[msg.sender]);
        
        emit Deposit(msg.sender, msg.value);
    }
    
    // 更新前10名存款人
    function updateTopDepositors(address user, uint amount) internal {
        uint userPos = userIndex[user];
        
        if (userPos > 0) {
            // 用户已在链表中，更新金额并调整位置
            topDepositors[userPos - 1].amount = amount;
            _reorderNode(userPos - 1);
        } else {
            // 用户不在链表中
            if (size < MAX_TOP_USERS) {
                // 链表未满，直接添加
                _addNode(user, amount);
            } else if (amount > topDepositors[topDepositors[head].next].amount) {
                // 链表已满，但用户存款大于链表中最小的存款，替换最小的
                _removeLastNode();
                _addNode(user, amount);
            }
        }
    }
    
    // 添加新节点到链表
    function _addNode(address user, uint amount) internal {
        // 创建新节点
        topDepositors.push(Node(user, amount, 0));
        uint newNodeIndex = topDepositors.length - 1;
        
        // 记录用户在链表中的位置
        userIndex[user] = newNodeIndex + 1;
        
        // 找到合适的位置插入
        uint current = head;
        while (topDepositors[current].next != 0 && 
               topDepositors[topDepositors[current].next].amount > amount) {
            current = topDepositors[current].next;
        }
        
        // 插入节点
        topDepositors[newNodeIndex].next = topDepositors[current].next;
        topDepositors[current].next = newNodeIndex;
        
        size++;
    }
    
    // 重新排序节点
    function _reorderNode(uint nodeIndex) internal {
        Node memory node = topDepositors[nodeIndex];
        
        // 先从链表中移除该节点
        uint current = head;
        while (topDepositors[current].next != nodeIndex && topDepositors[current].next != 0) {
            current = topDepositors[current].next;
        }
        
        if (topDepositors[current].next == nodeIndex) {
            topDepositors[current].next = topDepositors[nodeIndex].next;
            
            // 重新找到合适的位置插入
            current = head;
            while (topDepositors[current].next != 0 && 
                   topDepositors[topDepositors[current].next].amount > node.amount) {
                current = topDepositors[current].next;
            }
            
            // 插入节点
            topDepositors[nodeIndex].next = topDepositors[current].next;
            topDepositors[current].next = nodeIndex;
        }
    }
    
    // 移除链表中最后一个节点（存款金额最小的）
    function _removeLastNode() internal {
        if (size == 0) return;
        
        uint current = head;
        uint previous = head;
        
        // 找到倒数第二个节点
        while (topDepositors[current].next != 0) {
            previous = current;
            current = topDepositors[current].next;
        }
        
        // 移除最后一个节点
        address lastUser = topDepositors[current].user;
        userIndex[lastUser] = 0; // 标记用户不在链表中
        topDepositors[previous].next = 0;
        size--;
    }
    
    // 获取前10名存款人及其存款金额
    function getTopDepositors() external view returns (address[] memory, uint[] memory) {
        address[] memory users = new address[](size);
        uint[] memory amounts = new uint[](size);
        
        uint current = topDepositors[head].next;
        for (uint i = 0; i < size && current != 0; i++) {
            users[i] = topDepositors[current].user;
            amounts[i] = topDepositors[current].amount;
            current = topDepositors[current].next;
        }
        
        return (users, amounts);
    }
    
    // 只有管理员可以提取所有ETH
    function withdraw() external {
        require(msg.sender == admin, "Only admin can withdraw");
        
        uint balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        
        (bool success, ) = admin.call{value: balance}("");
        require(success, "Withdrawal failed");
        
        emit Withdraw(balance);
    }
}