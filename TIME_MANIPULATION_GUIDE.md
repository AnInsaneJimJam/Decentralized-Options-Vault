# Time Manipulation for DOV Testing

## 🕐 Understanding the Timing Issue

The DOV strategy requires a **7-day waiting period** between rolls. This is by design to simulate weekly option cycles.

## ⚡ Quick Fix for Testing

### Method 1: Anvil Time Manipulation

```bash
# Fast forward 7 days (604800 seconds)
cast rpc anvil_increaseTime 604800

# Mine a new block to apply the time change
cast rpc anvil_mine 1
```

### Method 2: Modify Contract for Testing

Temporarily change the roll interval to 1 minute for testing:

```solidity
uint256 public rollInterval = 1 minutes; // Instead of 7 days
```

### Method 3: Use Foundry Test Environment

In tests, we use:
```solidity
vm.warp(block.timestamp + 7 days + 1);
```

## 🎯 Step-by-Step Testing Process

1. **Deposit tokens** ✅ (Works immediately)
2. **Fast forward time** ⏰ (Use anvil_increaseTime)
3. **Roll strategy** 🎯 (Now available)
4. **Verify strategy active** ✅ (Should show active)
5. **Force settlement** 💰 (Generate yield)

## 🔧 Commands to Execute

```bash
# 1. Fast forward time
cast rpc anvil_increaseTime 604800
cast rpc anvil_mine 1

# 2. Check if roll is available
cast call $VAULT_ADDRESS "canRollStrategy()" --rpc-url http://localhost:8545

# 3. Roll the strategy
cast send $VAULT_ADDRESS "rollStrategy()" --private-key $PRIVATE_KEY --rpc-url http://localhost:8545

# 4. Verify strategy is active
cast call $VAULT_ADDRESS "strategyActive()" --rpc-url http://localhost:8545
```

## 🎮 Browser Testing After Time Manipulation

After running the time commands:
1. Refresh the DOV page
2. The "Roll Strategy" button should be enabled
3. Click it to activate the strategy
4. Strategy Active should show ✅
