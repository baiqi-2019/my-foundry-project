# DAO 治理系统

这是一个完整的去中心化自治组织（DAO）治理系统，通过代币投票来管理资金池的使用。

## 系统架构

### 1. VoteToken.sol - 治理代币合约
- **功能**: 可用于投票的 ERC20 代币
- **特性**:
  - 支持历史投票权重查询（检查点机制）
  - 自动跟踪每个地址的投票权重变化
  - 支持在指定区块高度查询投票权重
  - 铸造功能（仅所有者）

### 2. Bank.sol - 资金管理合约
- **功能**: 管理 DAO 的资金池
- **特性**:
  - 接收以太币存款
  - 提取资金（仅管理员）
  - 基于角色的访问控制
  - 防重入攻击保护

### 3. Gov.sol - 治理合约
- **功能**: 通过投票管理 Bank 合约
- **特性**:
  - 创建提案（需要最低代币门槛）
  - 投票机制（赞成/反对）
  - 提案执行（通过后自动执行）
  - 法定人数要求

## 工作流程

### 1. 创建提案
```solidity
function propose(
    string memory description,
    address payable target,
    uint256 amount,
    string memory reason
) external returns (uint256)
```

**要求**:
- 提案者必须拥有足够的投票权重（默认 1000 代币）
- 提案包含描述、目标地址、金额和原因

### 2. 投票过程
```solidity
function castVote(uint256 proposalId, bool support) external
```

**规则**:
- 投票权重基于提案创建时的代币余额
- 每个地址只能投票一次
- 投票期间为固定区块数（默认 100 区块）

### 3. 执行提案
```solidity
function execute(uint256 proposalId) external
```

**条件**:
- 投票期间结束
- 赞成票 > 反对票
- 赞成票 >= 法定人数（默认 4000 代币）

## 提案状态

- `Pending`: 待投票（投票尚未开始）
- `Active`: 投票中
- `Defeated`: 被否决（未达到法定人数或反对票更多）
- `Succeeded`: 通过（可以执行）
- `Executed`: 已执行

## 部署和测试

### 运行测试
```bash
forge test --match-path test/DAOTest.t.sol -vv
```

### 部署合约
```bash
forge script script/DeployDAO.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## 测试用例

### 1. 完整工作流程测试 (`testCompleteDAOWorkflow`)
- 创建提案
- 多用户投票
- 执行提案
- 验证资金转移

### 2. 失败提案测试 (`testDefeatedProposal`)
- 测试投票失败的情况
- 验证提案被正确否决

### 3. 投票权重不足测试 (`testInsufficientVotingPower`)
- 测试创建提案的门槛限制

### 4. 复杂投票场景测试 (`testComplexVotingScenario`)
- 测试平票和复杂投票情况

### 5. 事件日志测试 (`testEventLogs`)
- 验证所有关键事件的触发

## 安全特性

1. **重入攻击保护**: Bank 合约使用 ReentrancyGuard
2. **权限控制**: 基于角色的访问控制
3. **投票权重验证**: 基于历史快照防止闪电贷攻击
4. **法定人数**: 确保足够的参与度

## 治理参数

- `votingDelay`: 投票延迟（区块数）
- `votingPeriod`: 投票期间（区块数）
- `proposalThreshold`: 创建提案所需的最低代币数量
- `quorum`: 法定人数（提案通过所需的最低赞成票数）

## 事件

### VoteToken 事件
- `DelegateVotesChanged`: 投票权重变化

### Bank 事件
- `Deposit`: 存款
- `Withdraw`: 提取
- `AdminChanged`: 管理员变更

### Gov 事件
- `ProposalCreated`: 提案创建
- `VoteCast`: 投票
- `ProposalExecuted`: 提案执行

## 使用示例

```solidity
// 1. 部署合约
VoteToken token = new VoteToken("DAO Token", "DAO", 1000000e18, deployer);
Bank bank = new Bank(deployer);
Gov gov = new Gov(address(token), address(bank));

// 2. 设置权限
bank.addAdmin(address(gov));
bank.removeAdmin(deployer);

// 3. 创建提案
uint256 proposalId = gov.propose(
    "Fund development team",
    payable(developer),
    1 ether,
    "Q1 development milestone"
);

// 4. 投票
gov.castVote(proposalId, true); // 赞成

// 5. 执行（投票期间结束后）
gov.execute(proposalId);
```

这个 DAO 系统提供了一个完整的链上治理解决方案，可以安全地管理社区资金并通过民主投票做出决策。 