// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Bank {
    address public admin;
    mapping(address => uint) public deposits;
    
    // 链表节点结构
    struct Node {
        address user;
        uint amount;
        address next; // 下一个节点的地址
    }
    
    // 使用mapping存储链表节点
    mapping(address => Node) public nodes;
    address public head; // 链表头部地址
    address public tail; // 链表尾部地址
    uint public size; // 当前链表大小
    uint public constant MAX_TOP_USERS = 10; // 最多保存前10名
    
    // 事件
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event Deposit(address indexed user, uint amount);
    event Withdraw(uint amount);
    
    constructor() {
        admin = msg.sender;
        
        // 初始化链表，使用零地址作为哨兵节点
        head = address(0);
        tail = address(0);
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
        // 检查用户是否已在链表中
        bool isInList = false;
        address current = head;
        address prev = address(0);
        
        while (current != address(0)) {
            if (current == user) {
                isInList = true;
                break;
            }
            prev = current;
            current = nodes[current].next;
        }
        
        if (isInList) {
            // 用户已在链表中，更新金额并调整位置
            nodes[user].amount = amount;
            _reorderNode(user, prev);
        } else {
            // 用户不在链表中
            if (size < MAX_TOP_USERS) {
                // 链表未满，直接添加
                _addNode(user, amount);
            } else if (head != address(0) && amount > nodes[tail].amount) {
                // 链表已满，但用户存款大于链表中最小的存款，替换最小的
                _removeNode(tail);
                _addNode(user, amount);
            }
        }
    }
    
    // 添加新节点到链表
    function _addNode(address user, uint amount) internal {
        // 创建新节点
        nodes[user] = Node(user, amount, address(0));
        
        // 如果链表为空
        if (head == address(0)) {
            head = user;
            tail = user;
            size = 1;
            return;
        }
        
        // 找到合适的位置插入（按存款金额从大到小排序）
        address current = head;
        address prev = address(0);
        
        while (current != address(0) && nodes[current].amount >= amount) {
            prev = current;
            current = nodes[current].next;
        }
        
        // 插入节点
        if (prev == address(0)) {
            // 插入到链表头部
            nodes[user].next = head;
            head = user;
        } else {
            // 插入到中间或尾部
            nodes[user].next = nodes[prev].next;
            nodes[prev].next = user;
        }
        
        // 更新尾部指针
        if (nodes[user].next == address(0)) {
            tail = user;
        }
        
        size++;
    }
    
    // 重新排序节点
    function _reorderNode(address user, address prevNode) internal {
        // 如果只有一个节点，不需要重排
        if (size <= 1) return;
        
        // 从链表中移除节点
        if (prevNode == address(0)) {
            // 节点是头部
            head = nodes[user].next;
        } else {
            nodes[prevNode].next = nodes[user].next;
        }
        
        // 如果节点是尾部，更新尾部指针
        if (tail == user) {
            tail = prevNode == address(0) ? head : prevNode;
        }
        
        // 重新插入节点
        nodes[user].next = address(0);
        
        // 找到合适的位置重新插入
        address current = head;
        address prev = address(0);
        
        while (current != address(0) && nodes[current].amount >= nodes[user].amount && current != user) {
            prev = current;
            current = nodes[current].next;
        }
        
        // 重新插入节点
        if (prev == address(0)) {
            // 插入到链表头部
            nodes[user].next = head;
            head = user;
        } else {
            // 插入到中间或尾部
            nodes[user].next = nodes[prev].next;
            nodes[prev].next = user;
        }
        
        // 更新尾部指针
        if (nodes[user].next == address(0)) {
            tail = user;
        }
    }
    
    // 从链表中移除节点
    function _removeNode(address user) internal {
        if (size == 0) return;
        
        address current = head;
        address prev = address(0);
        
        // 找到要移除的节点
        while (current != address(0) && current != user) {
            prev = current;
            current = nodes[current].next;
        }
        
        // 如果找到了节点
        if (current == user) {
            // 移除节点
            if (prev == address(0)) {
                // 节点是头部
                head = nodes[user].next;
            } else {
                nodes[prev].next = nodes[user].next;
            }
            
            // 如果节点是尾部，更新尾部指针
            if (tail == user) {
                tail = prev == address(0) ? head : prev;
            }
            
            // 清除节点数据
            delete nodes[user];
            size--;
        }
    }
    
    // 获取前10名存款人及其存款金额
    function getTopDepositors() external view returns (address[] memory, uint[] memory) {
        address[] memory users = new address[](size);
        uint[] memory amounts = new uint[](size);
        
        address current = head;
        for (uint i = 0; i < size && current != address(0); i++) {
            users[i] = current;
            amounts[i] = nodes[current].amount;
            current = nodes[current].next;
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