//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/MockERC20.sol";
import "../contracts/MockStrategy.sol";
import "../contracts/CoveredCallVault.sol";

contract DOVEdgeCasesTest is Test {
    MockERC20 public mETH;
    MockStrategy public strategy;
    CoveredCallVault public vault;
    
    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public attacker = address(0x4);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy contracts
        mETH = new MockERC20("Mock ETH", "mETH", 18, 1000000, owner);
        strategy = new MockStrategy(address(mETH), owner);
        vault = new CoveredCallVault(mETH, "DOV Covered Call Vault", "DOV-CC", owner);
        
        // Setup connections
        strategy.setVault(address(vault));
        vault.setStrategy(address(strategy));
        
        // Transfer ownership for minting
        mETH.transferOwnership(address(strategy));
        
        // Mint tokens to users
        vm.startPrank(address(strategy));
        mETH.mint(user1, 1000 ether);
        mETH.mint(user2, 500 ether);
        mETH.mint(attacker, 100 ether);
        vm.stopPrank();
        
        vm.stopPrank();
    }
    
    function testZeroDeposit() public {
        vm.startPrank(user1);
        
        // Try to deposit 0 tokens
        mETH.approve(address(vault), 0);
        
        vm.expectRevert();
        vault.deposit(0, user1);
        
        vm.stopPrank();
    }
    
    function testZeroWithdraw() public {
        vm.startPrank(user1);
        
        // First make a deposit
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        
        // Try to withdraw 0 shares
        vm.expectRevert();
        vault.redeem(0, user1, user1);
        
        vm.stopPrank();
    }
    
    function testInsufficientBalance() public {
        vm.startPrank(user1);
        
        uint256 userBalance = mETH.balanceOf(user1);
        uint256 excessiveAmount = userBalance + 1 ether;
        
        // Try to deposit more than balance
        mETH.approve(address(vault), excessiveAmount);
        
        vm.expectRevert();
        vault.deposit(excessiveAmount, user1);
        
        vm.stopPrank();
    }
    
    function testInsufficientShares() public {
        vm.startPrank(user1);
        
        // Deposit some amount
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        
        // Try to withdraw more shares than owned
        vm.expectRevert();
        vault.redeem(shares + 1 ether, user1, user1);
        
        vm.stopPrank();
    }
    
    function testUnauthorizedStrategyRoll() public {
        vm.startPrank(user1);
        
        // Deposit funds first
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        
        vm.stopPrank();
        
        // Fast forward time
        vm.warp(block.timestamp + 7 days + 1);
        
        // Try to roll strategy as non-owner (should work - anyone can be keeper)
        vm.prank(user1);
        vault.rollStrategy();
        
        // Verify strategy is active
        assertTrue(vault.strategyActive());
    }
    
    function testPrematureStrategyRoll() public {
        vm.startPrank(user1);
        
        // Deposit funds
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        
        vm.stopPrank();
        
        // Try to roll strategy before 7 days
        vm.expectRevert("Too early to roll");
        vm.prank(owner);
        vault.rollStrategy();
    }
    
    function testMultipleUsersYieldDistribution() public {
        // User1 deposits 60 mETH
        vm.startPrank(user1);
        uint256 deposit1 = 60 ether;
        mETH.approve(address(vault), deposit1);
        uint256 shares1 = vault.deposit(deposit1, user1);
        vm.stopPrank();
        
        // User2 deposits 40 mETH
        vm.startPrank(user2);
        uint256 deposit2 = 40 ether;
        mETH.approve(address(vault), deposit2);
        uint256 shares2 = vault.deposit(deposit2, user2);
        vm.stopPrank();
        
        // Total: 100 mETH, User1: 60%, User2: 40%
        assertEq(vault.totalAssets(), 100 ether);
        
        // Fast forward and roll strategy
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(owner);
        vault.rollStrategy();
        
        // Force OTM outcome (profit)
        vm.prank(owner);
        strategy.forceSettle(0);
        
        // Check yield distribution
        uint256 totalAssets = vault.totalAssets();
        assertGt(totalAssets, 100 ether); // Should have gained yield
        
        // User1 should have 60% of total assets
        uint256 user1Assets = vault.convertToAssets(shares1);
        uint256 user2Assets = vault.convertToAssets(shares2);
        
        // Verify proportional distribution (allowing for rounding)
        assertApproxEqRel(user1Assets, (totalAssets * 60) / 100, 0.01e18); // 1% tolerance
        assertApproxEqRel(user2Assets, (totalAssets * 40) / 100, 0.01e18); // 1% tolerance
    }
    
    function testYieldGenerationAccuracy() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 100 ether;
        mETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        
        vm.stopPrank();
        
        // Initial state
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(vault.sharePrice(), 1e18); // 1.0 share price
        
        // Roll strategy
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(owner);
        vault.rollStrategy();
        
        // Verify strategy has funds and is active
        assertTrue(vault.strategyActive());
        assertEq(strategy.currentCollateral(), depositAmount);
        assertEq(strategy.currentPremium(), depositAmount * 5 / 100); // 5% premium
        
        // Force OTM settlement (profit scenario)
        vm.prank(owner);
        strategy.forceSettle(0);
        
        // Verify yield generation (allow for rounding errors)
        uint256 finalAssets = vault.totalAssets();
        uint256 expectedAssets = depositAmount + (depositAmount * 5 / 100); // Original + 5% premium
        
        assertApproxEqAbs(finalAssets, expectedAssets, 1); // Allow 1 wei difference
        
        // Verify share price appreciation
        uint256 finalSharePrice = vault.sharePrice();
        uint256 expectedSharePrice = 1.05e18; // 1.05 (5% increase)
        
        assertApproxEqAbs(finalSharePrice, expectedSharePrice, 1e15); // Allow small rounding
        
        // Verify user can withdraw more than deposited (allow for rounding)
        uint256 userAssets = vault.convertToAssets(shares);
        assertApproxEqAbs(userAssets, expectedAssets, 1);
    }
    
    function testLossScenario() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 100 ether;
        mETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        
        vm.stopPrank();
        
        // Roll strategy
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(owner);
        vault.rollStrategy();
        
        // Force ITM settlement (loss scenario)
        vm.prank(owner);
        strategy.forceSettle(1);
        
        // Verify loss
        uint256 finalAssets = vault.totalAssets();
        uint256 expectedAssets = depositAmount * 5 / 100; // Only premium remains (5%)
        
        assertEq(finalAssets, expectedAssets);
        
        // Verify share price depreciation
        uint256 finalSharePrice = vault.sharePrice();
        uint256 expectedSharePrice = 0.05e18; // 0.05 (95% loss)
        
        assertEq(finalSharePrice, expectedSharePrice);
        
        // User lost 95% of deposit
        uint256 userAssets = vault.convertToAssets(shares);
        assertEq(userAssets, expectedAssets);
    }
    
    function testWithdrawDuringActiveStrategy() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 100 ether;
        mETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user1);
        
        vm.stopPrank();
        
        // Roll strategy (funds are now locked in strategy)
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(owner);
        vault.rollStrategy();
        
        // Try to withdraw while strategy is active
        vm.startPrank(user1);
        vm.expectRevert("Insufficient liquid assets - wait for next strategy roll");
        vault.redeem(shares, user1, user1);
        vm.stopPrank();
    }
    
    function testEmergencySettlement() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 100 ether;
        mETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user1);
        
        vm.stopPrank();
        
        // Roll strategy
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(owner);
        vault.rollStrategy();
        
        // Emergency settle
        vm.prank(owner);
        vault.emergencySettleStrategy();
        
        // Strategy should no longer be active
        assertFalse(vault.strategyActive());
        
        // Assets should be returned to vault
        assertGt(vault.totalAssets(), 0);
    }
    
    function testStrategyParameterChanges() public {
        // Test premium rate change
        uint256 initialRate = strategy.premiumRate();
        assertEq(initialRate, 500); // 5%
        
        // Change premium rate
        vm.prank(owner);
        strategy.setPremiumRate(1000); // 10%
        
        assertEq(strategy.premiumRate(), 1000);
        
        // Test invalid premium rate
        vm.expectRevert("Premium rate too high (max 20%)");
        vm.prank(owner);
        strategy.setPremiumRate(2001); // 20.01%
    }
    
    function testRollIntervalChanges() public {
        // Test roll interval change
        uint256 initialInterval = vault.rollInterval();
        assertEq(initialInterval, 7 days);
        
        // Change roll interval
        vm.prank(owner);
        vault.setRollInterval(3 days);
        
        assertEq(vault.rollInterval(), 3 days);
        
        // Test invalid intervals
        vm.expectRevert("Roll interval too short");
        vm.prank(owner);
        vault.setRollInterval(30 minutes);
        
        vm.expectRevert("Roll interval too long");
        vm.prank(owner);
        vault.setRollInterval(31 days);
    }
}
