// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/StakingPool.sol";
import "../src/KKToken.sol";
import "../src/MockWETH.sol";
import "../src/MockLendingPool.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    KKToken public kkToken;
    MockWETH public weth;
    MockLendingPool public lendingPool;
    
    address public owner;
    address public user1;
    address public user2;
    
    uint256 public constant STAKE_AMOUNT = 1 ether;
    uint256 public constant REWARD_PER_BLOCK = 10 * 1e18;
    
    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        // 部署合约
        kkToken = new KKToken();
        weth = new MockWETH();
        lendingPool = new MockLendingPool();
        stakingPool = new StakingPool(address(kkToken), address(weth), address(lendingPool));
        
        // 给StakingPool添加mint权限
        kkToken.addMinter(address(stakingPool));
        
        // 给用户一些ETH
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);
    }
    
    function testDeployment() public {
        assertEq(address(stakingPool.kkToken()), address(kkToken));
        assertEq(address(stakingPool.weth()), address(weth));
        assertEq(address(stakingPool.lendingPool()), address(lendingPool));
        assertEq(stakingPool.owner(), owner);
        assertEq(stakingPool.REWARD_PER_BLOCK(), REWARD_PER_BLOCK);
    }
    
    function testStake() public {
        vm.startPrank(user1);
        
        // 质押前的状态检查
        assertEq(stakingPool.balanceOf(user1), 0);
        assertEq(stakingPool.totalStaked(), 0);
        
        // 执行质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 质押后的状态检查
        assertEq(stakingPool.balanceOf(user1), STAKE_AMOUNT);
        assertEq(stakingPool.totalStaked(), STAKE_AMOUNT);
        
        // 检查用户信息
        (uint256 amount, uint256 rewardDebt, uint256 stakingTime) = stakingPool.userInfo(user1);
        assertEq(amount, STAKE_AMOUNT);
        assertEq(rewardDebt, 0); // 首次质押，奖励债务为0
        assertGt(stakingTime, 0); // 质押时间应该大于0
        
        vm.stopPrank();
    }
    
    function testCannotStakeZero() public {
        vm.startPrank(user1);
        
        vm.expectRevert("Cannot stake 0");
        stakingPool.stake{value: 0}();
        
        vm.stopPrank();
    }
    
    function testMultipleStakes() public {
        vm.startPrank(user1);
        
        // 第一次质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        assertEq(stakingPool.balanceOf(user1), STAKE_AMOUNT);
        
        // 等待几个区块
        vm.roll(block.number + 5);
        
        // 第二次质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        assertEq(stakingPool.balanceOf(user1), STAKE_AMOUNT * 2);
        assertEq(stakingPool.totalStaked(), STAKE_AMOUNT * 2);
        
        vm.stopPrank();
    }
    
    function testUnstake() public {
        vm.startPrank(user1);
        
        // 先质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 等待几个区块产生奖励
        vm.roll(block.number + 10);
        
        uint256 balanceBefore = user1.balance;
        
        // 部分解质押
        uint256 unstakeAmount = STAKE_AMOUNT / 2;
        stakingPool.unstake(unstakeAmount);
        
        // 检查状态
        assertEq(stakingPool.balanceOf(user1), STAKE_AMOUNT - unstakeAmount);
        assertEq(stakingPool.totalStaked(), STAKE_AMOUNT - unstakeAmount);
        assertEq(user1.balance, balanceBefore + unstakeAmount);
        
        // 检查是否获得了KK Token奖励
        assertGt(kkToken.balanceOf(user1), 0);
        
        vm.stopPrank();
    }
    
    function testUnstakeAll() public {
        vm.startPrank(user1);
        
        // 先质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 等待几个区块
        vm.roll(block.number + 5);
        
        uint256 balanceBefore = user1.balance;
        
        // 全部解质押
        stakingPool.unstake(STAKE_AMOUNT);
        
        // 检查状态
        assertEq(stakingPool.balanceOf(user1), 0);
        assertEq(stakingPool.totalStaked(), 0);
        assertEq(user1.balance, balanceBefore + STAKE_AMOUNT);
        
        // 检查质押时间是否重置
        (, , uint256 stakingTime) = stakingPool.userInfo(user1);
        assertEq(stakingTime, 0);
        
        vm.stopPrank();
    }
    
    function testCannotUnstakeMoreThanStaked() public {
        vm.startPrank(user1);
        
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        vm.expectRevert("Invalid amount");
        stakingPool.unstake(STAKE_AMOUNT + 1 ether);
        
        vm.stopPrank();
    }
    
    function testCannotUnstakeZero() public {
        vm.startPrank(user1);
        
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        vm.expectRevert("Invalid amount");
        stakingPool.unstake(0);
        
        vm.stopPrank();
    }
    
    function testClaim() public {
        vm.startPrank(user1);
        
        // 质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 等待10个区块
        vm.roll(block.number + 10);
        
        uint256 earnedBefore = stakingPool.earned(user1);
        assertGt(earnedBefore, 0);
        
        // 领取奖励
        stakingPool.claim();
        
        // 检查KK Token余额
        assertEq(kkToken.balanceOf(user1), earnedBefore);
        
        // 领取后earned应该为0
        assertEq(stakingPool.earned(user1), 0);
        
        vm.stopPrank();
    }
    
    function testCannotClaimWithoutRewards() public {
        vm.startPrank(user1);
        
        // 质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 立即尝试领取奖励（没有等待区块）
        vm.expectRevert("No rewards");
        stakingPool.claim();
        
        vm.stopPrank();
    }
    
    function testEarned() public {
        vm.startPrank(user1);
        
        // 质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 初始earned应该为0
        assertEq(stakingPool.earned(user1), 0);
        
        // 等待5个区块
        vm.roll(block.number + 5);
        
        // 计算期望的奖励: 5个区块 * 10 KK Token / 区块 = 50 KK Token
        uint256 expectedReward = 5 * REWARD_PER_BLOCK;
        assertEq(stakingPool.earned(user1), expectedReward);
        
        vm.stopPrank();
    }
    
    function testRewardDistribution() public {
        // user1质押1 ETH
        vm.prank(user1);
        stakingPool.stake{value: 1 ether}();
        
        // user2质押2 ETH
        vm.prank(user2);
        stakingPool.stake{value: 2 ether}();
        
        // 等待6个区块
        vm.roll(block.number + 6);
        
        uint256 user1Earned = stakingPool.earned(user1);
        uint256 user2Earned = stakingPool.earned(user2);
        
        // 验证总奖励分配正确
        uint256 totalReward = user1Earned + user2Earned;
        uint256 expectedTotalReward = 6 * REWARD_PER_BLOCK; // 6个区块的总奖励
        assertEq(totalReward, expectedTotalReward);
        
        // user2应该得到更多奖励（因为质押了更多ETH）
        assertGt(user2Earned, user1Earned);
        
        // 大致验证奖励比例（user2质押了2倍，但晚了1个区块）
        // user1在第一个区块独享奖励，之后按比例分配
        // 期望 user2 的奖励大于 user1，但不会是 2 倍关系
        assertGt(user2Earned, user1Earned * 3 / 2); // user2 应该至少比 user1 多 50%
    }
    
    function testLendingPoolIntegration() public {
        vm.startPrank(user1);
        
        // 质押前检查借贷池余额
        assertEq(lendingPool.getBalance(address(stakingPool), address(weth)), 0);
        
        // 质押
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        // 检查WETH是否存入借贷池
        assertEq(lendingPool.getBalance(address(stakingPool), address(weth)), STAKE_AMOUNT);
        
        // 解质押
        stakingPool.unstake(STAKE_AMOUNT);
        
        // 检查WETH是否从借贷池提取
        assertEq(lendingPool.getBalance(address(stakingPool), address(weth)), 0);
        
        vm.stopPrank();
    }
    
    function testGetStakingTime() public {
        vm.startPrank(user1);
        
        uint256 stakingTimeBefore = stakingPool.getStakingTime(user1);
        assertEq(stakingTimeBefore, 0);
        
        // 质押
        uint256 stakeTimestamp = block.timestamp;
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        uint256 stakingTimeAfter = stakingPool.getStakingTime(user1);
        assertEq(stakingTimeAfter, stakeTimestamp);
        
        vm.stopPrank();
    }
    
    function testOnlyOwnerFunctions() public {
        address notOwner = makeAddr("notOwner");
        
        // 测试updateLendingPool只能由owner调用
        vm.prank(notOwner);
        vm.expectRevert("Not owner");
        stakingPool.updateLendingPool(address(0));
        
        // owner可以正常调用
        stakingPool.updateLendingPool(address(lendingPool));
        
        // 测试emergencyWithdraw只能由owner调用
        vm.prank(notOwner);
        vm.expectRevert("Not owner");
        stakingPool.emergencyWithdraw();
    }
    
    function testEmergencyWithdraw() public {
        // 向合约发送一些ETH
        vm.deal(address(stakingPool), 5 ether);
        
        uint256 ownerBalanceBefore = owner.balance;
        
        // 紧急提取
        stakingPool.emergencyWithdraw();
        
        uint256 ownerBalanceAfter = owner.balance;
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 5 ether);
        assertEq(address(stakingPool).balance, 0);
    }
    
    function testReceiveFunction() public {
        // 测试合约可以接收ETH
        vm.deal(user1, 1 ether);
        
        vm.prank(user1);
        (bool success, ) = payable(address(stakingPool)).call{value: 0.5 ether}("");
        assertTrue(success);
        
        assertEq(address(stakingPool).balance, 0.5 ether);
    }
    
    function testUpdateReward() public {
        // 测试奖励更新机制
        vm.startPrank(user1);
        
        stakingPool.stake{value: STAKE_AMOUNT}();
        
        uint256 lastRewardBlockBefore = stakingPool.lastRewardBlock();
        uint256 accRewardPerShareBefore = stakingPool.accRewardPerShare();
        
        // 等待几个区块
        vm.roll(block.number + 3);
        
        // 手动更新奖励
        stakingPool.updateReward();
        
        uint256 lastRewardBlockAfter = stakingPool.lastRewardBlock();
        uint256 accRewardPerShareAfter = stakingPool.accRewardPerShare();
        
        // 检查更新
        assertGt(lastRewardBlockAfter, lastRewardBlockBefore);
        assertGt(accRewardPerShareAfter, accRewardPerShareBefore);
        
        vm.stopPrank();
    }
    
    // 添加receive函数以支持接收ETH（用于emergencyWithdraw测试）
    receive() external payable {}
} 