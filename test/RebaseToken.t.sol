// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Rebase_Token.sol";

contract RebaseTokenTest is Test {
    RebaseToken public token;
    address public owner;
    address public user1;
    address public user2;
    
    uint256 constant INITIAL_SUPPLY = 100_000_000 * 10**18;
    uint256 constant DEFLATION_RATE = 99;
    uint256 constant RATE_DENOMINATOR = 100;

    event Rebase(uint256 indexed epoch, uint256 totalSupply);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        token = new RebaseToken();
    }

    function testInitialState() public {
        assertEq(token.name(), "Rebase Deflation Token");
        assertEq(token.symbol(), "RDT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.rebaseCount(), 0);
    }

    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        uint256 ownerBalanceBefore = token.balanceOf(owner);
        uint256 user1BalanceBefore = token.balanceOf(user1);
        
        token.transfer(user1, transferAmount);
        
        assertEq(token.balanceOf(owner), ownerBalanceBefore - transferAmount);
        assertEq(token.balanceOf(user1), user1BalanceBefore + transferAmount);
    }

    function testManualRebase() public {
        uint256 initialTotalSupply = token.totalSupply();
        uint256 transferAmount = 5_000_000 * 10**18;
        
        token.transfer(user1, transferAmount);
        token.transfer(user2, transferAmount);
        
        uint256 ownerBalance = token.balanceOf(owner);
        uint256 user1Balance = token.balanceOf(user1);
        uint256 user2Balance = token.balanceOf(user2);
        
        token.manualRebase();
        
        uint256 expectedNewTotalSupply = (initialTotalSupply * DEFLATION_RATE) / RATE_DENOMINATOR;
        assertEq(token.totalSupply(), expectedNewTotalSupply);
        
        assertEq(token.balanceOf(owner), (ownerBalance * DEFLATION_RATE) / RATE_DENOMINATOR);
        assertEq(token.balanceOf(user1), (user1Balance * DEFLATION_RATE) / RATE_DENOMINATOR);
        assertEq(token.balanceOf(user2), (user2Balance * DEFLATION_RATE) / RATE_DENOMINATOR);
    }

    function testRebaseAfterOneYear() public {
        uint256 initialTotalSupply = token.totalSupply();
        uint256 transferAmount = 10_000_000 * 10**18;
        
        token.transfer(user1, transferAmount);
        
        uint256 ownerBalance = token.balanceOf(owner);
        uint256 user1Balance = token.balanceOf(user1);
        
        vm.warp(block.timestamp + 365 days);
        
        vm.expectEmit(true, false, false, true);
        emit Rebase(1, (initialTotalSupply * DEFLATION_RATE) / RATE_DENOMINATOR);
        
        token.rebase();
        
        uint256 expectedNewTotalSupply = (initialTotalSupply * DEFLATION_RATE) / RATE_DENOMINATOR;
        assertEq(token.totalSupply(), expectedNewTotalSupply);
        assertEq(token.rebaseCount(), 1);
        
        uint256 expectedOwnerBalance = (ownerBalance * DEFLATION_RATE) / RATE_DENOMINATOR;
        uint256 expectedUser1Balance = (user1Balance * DEFLATION_RATE) / RATE_DENOMINATOR;
        
        assertEq(token.balanceOf(owner), expectedOwnerBalance);
        assertEq(token.balanceOf(user1), expectedUser1Balance);
        
        assertEq(token.balanceOf(owner) + token.balanceOf(user1), token.totalSupply());
    }

    function testMultipleRebase() public {
        uint256 initialSupply = token.totalSupply();
        uint256 transferAmount = 1_000_000 * 10**18;
        
        token.transfer(user1, transferAmount);
        
        token.manualRebase();
        uint256 supplyAfterFirst = token.totalSupply();
        uint256 expectedAfterFirst = (initialSupply * DEFLATION_RATE) / RATE_DENOMINATOR;
        assertEq(supplyAfterFirst, expectedAfterFirst);
        
        token.manualRebase();
        uint256 supplyAfterSecond = token.totalSupply();
        uint256 expectedAfterSecond = (expectedAfterFirst * DEFLATION_RATE) / RATE_DENOMINATOR;
        assertEq(supplyAfterSecond, expectedAfterSecond);
        
        assertEq(token.rebaseCount(), 2);
        
        uint256 user1ExpectedBalance = (transferAmount * DEFLATION_RATE * DEFLATION_RATE) / (RATE_DENOMINATOR * RATE_DENOMINATOR);
        assertEq(token.balanceOf(user1), user1ExpectedBalance);
    }

    function testRebaseFailsIfTooEarly() public {
        vm.expectRevert("Rebase too early");
        token.rebase();
        
        vm.warp(block.timestamp + 364 days);
        
        vm.expectRevert("Rebase too early");
        token.rebase();
    }

    function testCanRebaseFunction() public {
        assertFalse(token.canRebase());
        
        vm.warp(block.timestamp + 365 days);
        assertTrue(token.canRebase());
    }

    function testNextRebaseTime() public {
        uint256 initialTime = block.timestamp;
        uint256 expectedNextRebaseTime = initialTime + 365 days;
        
        assertEq(token.nextRebaseTime(), expectedNextRebaseTime);
    }

    function testGonBalances() public {
        uint256 transferAmount = 1000 * 10**18;
        
        uint256 ownerGonsBefore = token.gonBalanceOf(owner);
        uint256 user1GonsBefore = token.gonBalanceOf(user1);
        
        token.transfer(user1, transferAmount);
        
        uint256 gonValue = transferAmount * token.gonsPerFragment();
        assertEq(token.gonBalanceOf(owner), ownerGonsBefore - gonValue);
        assertEq(token.gonBalanceOf(user1), user1GonsBefore + gonValue);
        
        token.manualRebase();
        
        assertEq(token.gonBalanceOf(owner), ownerGonsBefore - gonValue);
        assertEq(token.gonBalanceOf(user1), user1GonsBefore + gonValue);
        
        uint256 expectedTokenBalance = (transferAmount * DEFLATION_RATE) / RATE_DENOMINATOR;
        assertEq(token.balanceOf(user1), expectedTokenBalance);
    }

    function testOnlyOwnerCanRebase() public {
        vm.prank(user1);
        vm.expectRevert("Not owner");
        token.rebase();
        
        vm.prank(user1);
        vm.expectRevert("Not owner");
        token.manualRebase();
    }

    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 2000 * 10**18;
        uint256 transferAmount = 1000 * 10**18;
        
        token.approve(user1, approveAmount);
        assertEq(token.allowance(owner, user1), approveAmount);
        
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);
        
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(owner, user1), approveAmount - transferAmount);
    }

    function testIncreaseDecreaseAllowance() public {
        uint256 initialAllowance = 1000 * 10**18;
        uint256 increaseAmount = 500 * 10**18;
        uint256 decreaseAmount = 300 * 10**18;
        
        token.approve(user1, initialAllowance);
        assertEq(token.allowance(owner, user1), initialAllowance);
        
        token.increaseAllowance(user1, increaseAmount);
        assertEq(token.allowance(owner, user1), initialAllowance + increaseAmount);
        
        token.decreaseAllowance(user1, decreaseAmount);
        assertEq(token.allowance(owner, user1), initialAllowance + increaseAmount - decreaseAmount);
        
        token.decreaseAllowance(user1, initialAllowance + increaseAmount);
        assertEq(token.allowance(owner, user1), 0);
    }
}