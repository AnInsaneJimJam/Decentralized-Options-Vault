//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MockERC20.sol";
import "forge-std/console.sol";

/**
 * Mock Strategy contract that simulates covered call option trading
 * @author DOV Team
 */
contract MockStrategy is Ownable {
    IERC20 public immutable asset;
    address public vault;
    
    // Strategy state
    uint256 public currentCollateral;
    uint256 public currentPremium;
    uint256 public premiumRate = 500; // 5% in basis points (500/10000)
    
    // Option status: 0 = OTM (Out of The Money), 1 = ITM (In The Money)
    uint8 public optionStatus;
    
    // Track if we have an active position
    bool public hasActivePosition;
    
    // Events
    event CollateralDeposited(uint256 amount);
    event OptionSold(uint256 collateral, uint256 premium);
    event TradeSettled(uint256 assetsReturned, uint8 optionStatus);
    event PremiumRateUpdated(uint256 newRate);

    modifier onlyVault() {
        require(msg.sender == vault, "Only vault can call this function");
        _;
    }

    constructor(address _asset, address _owner) Ownable(_owner) {
        asset = IERC20(_asset);
    }

    /**
     * Set the vault address (can only be called by owner)
     */
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    /**
     * Accept collateral from the vault before option sale
     */
    function depositCollateral(uint256 amount) external onlyVault {
        require(amount > 0, "Amount must be greater than 0");
        require(!hasActivePosition, "Already have active position");
        
        bool success = asset.transferFrom(vault, address(this), amount);
        require(success, "Transfer failed");
        
        currentCollateral = amount;
        emit CollateralDeposited(amount);
        
        console.log("Collateral deposited:", amount);
    }

    /**
     * Execute option sale - simulates selling a covered call
     */
    function executeOptionSale(uint256 collateral) external onlyVault {
        require(collateral > 0, "Collateral must be greater than 0");
        require(currentCollateral >= collateral, "Insufficient collateral");
        
        // Calculate premium (e.g., 5% of collateral)
        currentPremium = (collateral * premiumRate) / 10000;
        hasActivePosition = true;
        
        // Simulate receiving premium - in reality this would come from options exchange
        // For testing, we'll mint the premium to this contract
        MockERC20(address(asset)).mint(address(this), currentPremium);
        
        emit OptionSold(collateral, currentPremium);
        console.log("Option sold - Collateral:", collateral, "Premium:", currentPremium);
    }

    /**
     * Settle the trade based on option outcome
     * Returns the total assets that should be returned to the vault
     */
    function settleTrade() external onlyVault returns (uint256) {
        require(hasActivePosition, "No active position to settle");
        
        // Simulate option outcome (for demo, we'll use a simple random-like mechanism)
        // In practice, this would be determined by comparing strike price to market price
        optionStatus = uint8(block.timestamp % 2); // Simple pseudo-random: 0 or 1
        
        uint256 assetsToReturn;
        
        if (optionStatus == 0) {
            // OTM: Keep collateral + premium
            assetsToReturn = currentCollateral + currentPremium;
            console.log("Option expired OTM - Profit:", currentPremium);
        } else {
            // ITM: Collateral exercised, keep only premium
            assetsToReturn = currentPremium;
            console.log("Option expired ITM - Loss:", currentCollateral - currentPremium);
        }
        
        // Reset state
        hasActivePosition = false;
        currentCollateral = 0;
        currentPremium = 0;
        
        // Transfer assets back to vault
        if (assetsToReturn > 0) {
            bool success = asset.transfer(vault, assetsToReturn);
            require(success, "Transfer back to vault failed");
        }
        
        emit TradeSettled(assetsToReturn, optionStatus);
        return assetsToReturn;
    }

    /**
     * Get the total assets that would be returned if settled now
     */
    function getAssetsToReturn() external view returns (uint256) {
        if (!hasActivePosition) {
            return 0;
        }
        
        // For demo purposes, assume OTM outcome for preview
        return currentCollateral + currentPremium;
    }

    /**
     * Update premium rate (governance function)
     */
    function setPremiumRate(uint256 _premiumRate) external onlyOwner {
        require(_premiumRate <= 2000, "Premium rate too high (max 20%)");
        premiumRate = _premiumRate;
        emit PremiumRateUpdated(_premiumRate);
    }

    /**
     * Force settle with specific outcome (for testing)
     */
    function forceSettle(uint8 _optionStatus) external onlyOwner {
        require(hasActivePosition, "No active position");
        require(_optionStatus <= 1, "Invalid option status");
        
        optionStatus = _optionStatus;
        
        uint256 assetsToReturn;
        if (optionStatus == 0) {
            assetsToReturn = currentCollateral + currentPremium;
        } else {
            assetsToReturn = currentPremium;
        }
        
        hasActivePosition = false;
        currentCollateral = 0;
        currentPremium = 0;
        
        if (assetsToReturn > 0) {
            bool success = asset.transfer(vault, assetsToReturn);
            require(success, "Transfer back to vault failed");
        }
        
        emit TradeSettled(assetsToReturn, optionStatus);
    }

    /**
     * Emergency withdraw (owner only)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = asset.balanceOf(address(this));
        if (balance > 0) {
            bool success = asset.transfer(owner(), balance);
            require(success, "Emergency withdraw failed");
        }
        
        // Reset state
        hasActivePosition = false;
        currentCollateral = 0;
        currentPremium = 0;
    }
}
