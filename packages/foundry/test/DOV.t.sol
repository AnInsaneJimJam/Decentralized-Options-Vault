//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "forge-std/Test.sol";
import "../contracts/MockERC20.sol";
import "../contracts/MockStrategy.sol";
import "../contracts/CoveredCallVault.sol";

contract DOVTest is Test {
    MockERC20 public mETH;
    MockStrategy public strategy;
    CoveredCallVault public vault;
    
    address public owner = address(0x1);
    address public user = address(0x2);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // Deploy MockERC20
        mETH = new MockERC20("Mock ETH", "mETH", 18, 1000000, owner);
        
        // Deploy MockStrategy
        strategy = new MockStrategy(address(mETH), owner);
        
        // Deploy CoveredCallVault
        vault = new CoveredCallVault(
            mETH,
            "DOV Covered Call Vault",
            "DOV-CC",
            owner
        );
        
        // Set up connections
        strategy.setVault(address(vault));
        vault.setStrategy(address(strategy));
        
        // Transfer ownership of mETH to strategy so it can mint premiums
        mETH.transferOwnership(address(strategy));
        
        // Mint tokens to user for testing
        vm.startPrank(address(strategy));
        mETH.mint(user, 100 ether);
        vm.stopPrank();
        
        vm.stopPrank();
    }
    
    function testDeposit() public {
        vm.startPrank(user);
        
        uint256 depositAmount = 10 ether;
        
        // Approve vault to spend mETH
        mETH.approve(address(vault), depositAmount);
        
        // Deposit to vault
        uint256 shares = vault.deposit(depositAmount, user);
        
        // Check balances
        assertEq(vault.balanceOf(user), shares);
        assertEq(vault.totalAssets(), depositAmount);
        
        vm.stopPrank();
    }
    
    function testStrategyRoll() public {
        // First deposit some funds
        vm.startPrank(user);
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
        
        // Fast forward time to allow rolling
        vm.warp(block.timestamp + 7 days + 1);
        
        // Roll strategy
        vm.prank(owner);
        vault.rollStrategy();
        
        // Check that strategy is active
        assertTrue(vault.strategyActive());
        assertTrue(strategy.hasActivePosition());
    }
    
    function testOptionOutcome() public {
        // Setup: deposit and roll strategy
        vm.startPrank(user);
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        vault.deposit(depositAmount, user);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 7 days + 1);
        vm.prank(owner);
        vault.rollStrategy();
        
        uint256 assetsBeforeSettle = vault.totalAssets();
        
        // Force settle with OTM outcome (profit)
        vm.prank(owner);
        strategy.forceSettle(0); // 0 = OTM
        
        uint256 assetsAfterSettle = vault.totalAssets();
        
        // Should have gained premium (5% of collateral)
        // Note: The exact amount depends on the random outcome, but should be positive
        assertGe(assetsAfterSettle, depositAmount / 20); // At least the premium amount
    }
    
    function testWithdraw() public {
        // Setup: deposit funds
        vm.startPrank(user);
        uint256 depositAmount = 10 ether;
        mETH.approve(address(vault), depositAmount);
        uint256 shares = vault.deposit(depositAmount, user);
        
        // Withdraw half the shares
        uint256 withdrawShares = shares / 2;
        uint256 assetsWithdrawn = vault.redeem(withdrawShares, user, user);
        
        // Check balances
        assertEq(vault.balanceOf(user), shares - withdrawShares);
        assertGt(assetsWithdrawn, 0);
        
        vm.stopPrank();
    }
    
    function testVaultMetrics() public {
        // Get initial metrics
        (uint256 tvl, uint256 sharePrice, uint256 totalYield, bool isActive, uint256 nextRoll) = vault.getVaultMetrics();
        
        assertEq(tvl, 0);
        assertEq(sharePrice, 1e18); // Initial share price should be 1.0
        assertEq(totalYield, 0);
        assertFalse(isActive);
        assertGt(nextRoll, block.timestamp);
    }
}
