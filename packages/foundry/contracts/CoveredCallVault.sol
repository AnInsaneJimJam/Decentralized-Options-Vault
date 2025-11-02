//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./MockStrategy.sol";
import "forge-std/console.sol";

/**
 * Covered Call Vault implementing ERC-4626 standard
 * Automatically manages covered call strategies to generate yield
 * @author DOV Team
 */
contract CoveredCallVault is ERC4626, Ownable, ReentrancyGuard {
    MockStrategy public strategy;
    
    // Time tracking for strategy rolls
    uint256 public lastRollTime;
    uint256 public rollInterval = 7 days; // Weekly cycles
    
    // Vault state
    bool public strategyActive;
    uint256 public totalYieldGenerated;
    
    // Events
    event StrategySet(address indexed strategy);
    event StrategyRolled(uint256 timestamp, uint256 assetsInStrategy);
    event YieldGenerated(uint256 amount);
    event RollIntervalUpdated(uint256 newInterval);

    constructor(
        IERC20 _asset,
        string memory _name,
        string memory _symbol,
        address _owner
    ) ERC4626(_asset) ERC20(_name, _symbol) Ownable(_owner) {
        lastRollTime = block.timestamp;
    }

    /**
     * Set the strategy contract address
     */
    function setStrategy(address _strategy) external onlyOwner {
        strategy = MockStrategy(_strategy);
        emit StrategySet(_strategy);
    }

    /**
     * Roll the strategy - settle current position and start new one
     * This is the main keeper function that should be called periodically
     */
    function rollStrategy() external nonReentrant {
        require(address(strategy) != address(0), "Strategy not set");
        require(block.timestamp >= lastRollTime + rollInterval, "Too early to roll");
        
        uint256 assetsBeforeRoll = totalAssets();
        
        // Step 1: Settle previous trade if there was one
        if (strategyActive) {
            uint256 assetsReturned = strategy.settleTrade();
            console.log("Assets returned from strategy:", assetsReturned);
            
            // Calculate yield generated
            if (assetsReturned > 0) {
                uint256 yield = assetsReturned > assetsBeforeRoll ? 
                    assetsReturned - assetsBeforeRoll : 0;
                if (yield > 0) {
                    totalYieldGenerated += yield;
                    emit YieldGenerated(yield);
                }
            }
        }
        
        // Step 2: Send current assets to strategy for new position
        uint256 currentAssets = totalAssets();
        if (currentAssets > 0) {
            // Approve strategy to take assets
            IERC20(asset()).approve(address(strategy), currentAssets);
            
            // Deposit collateral to strategy
            strategy.depositCollateral(currentAssets);
            
            // Execute option sale
            strategy.executeOptionSale(currentAssets);
            
            strategyActive = true;
        }
        
        lastRollTime = block.timestamp;
        emit StrategyRolled(block.timestamp, currentAssets);
        
        console.log("Strategy rolled with assets:", currentAssets);
    }

    /**
     * Override totalAssets to include assets in strategy
     */
    function totalAssets() public view override returns (uint256) {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
        
        if (address(strategy) != address(0) && strategyActive) {
            uint256 strategyAssets = strategy.getAssetsToReturn();
            return vaultBalance + strategyAssets;
        }
        
        return vaultBalance;
    }

    /**
     * Override _deposit to handle strategy integration
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        require(assets > 0, "Cannot deposit zero assets");
        require(shares > 0, "Cannot mint zero shares");
        super._deposit(caller, receiver, assets, shares);
        console.log("Deposit - Assets:", assets, "Shares:", shares);
    }

    /**
     * Override _withdraw to handle strategy assets if needed
     */
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        require(assets > 0, "Cannot withdraw zero assets");
        require(shares > 0, "Cannot burn zero shares");
        
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
        
        // If we don't have enough assets in vault, we might need to settle strategy
        if (assets > vaultBalance && strategyActive) {
            // For simplicity, we'll revert if trying to withdraw more than vault balance
            // In a production system, you might want to partially settle the strategy
            revert("Insufficient liquid assets - wait for next strategy roll");
        }
        
        super._withdraw(caller, receiver, owner, assets, shares);
        console.log("Withdraw - Assets:", assets, "Shares:", shares);
    }

    /**
     * Get the current share price (assets per share)
     */
    function sharePrice() external view returns (uint256) {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return 10**decimals(); // Initial price of 1.0
        }
        return (totalAssets() * 10**decimals()) / supply;
    }

    /**
     * Get vault performance metrics
     */
    function getVaultMetrics() external view returns (
        uint256 tvl,
        uint256 sharePrice_,
        uint256 totalYield,
        bool isStrategyActive,
        uint256 nextRollTime
    ) {
        tvl = totalAssets();
        sharePrice_ = this.sharePrice();
        totalYield = totalYieldGenerated;
        isStrategyActive = strategyActive;
        nextRollTime = lastRollTime + rollInterval;
    }

    /**
     * Update roll interval (governance function)
     */
    function setRollInterval(uint256 _rollInterval) external onlyOwner {
        require(_rollInterval >= 1 hours, "Roll interval too short");
        require(_rollInterval <= 30 days, "Roll interval too long");
        rollInterval = _rollInterval;
        emit RollIntervalUpdated(_rollInterval);
    }

    /**
     * Emergency function to force settle strategy
     */
    function emergencySettleStrategy() external onlyOwner {
        require(strategyActive, "No active strategy");
        strategy.settleTrade();
        strategyActive = false;
    }

    /**
     * Check if strategy can be rolled
     */
    function canRollStrategy() external view returns (bool) {
        return block.timestamp >= lastRollTime + rollInterval;
    }

    /**
     * Time until next roll is available
     */
    function timeUntilNextRoll() external view returns (uint256) {
        uint256 nextRoll = lastRollTime + rollInterval;
        if (block.timestamp >= nextRoll) {
            return 0;
        }
        return nextRoll - block.timestamp;
    }
}
