# DOV Manual Testing Guide

## 🎯 Complete Testing Checklist

This guide provides step-by-step instructions for comprehensive manual testing of the DOV application.

## 🔧 Pre-Testing Setup

### Environment Verification
- [ ] Local blockchain running (`yarn foundry:chain`)
- [ ] Contracts deployed (`yarn foundry:deploy`)
- [ ] Frontend running (`yarn start`)
- [ ] Browser with MetaMask installed

### MetaMask Configuration
1. **Add Local Network**:
   - Network Name: `Localhost 8545`
   - RPC URL: `http://127.0.0.1:8545`
   - Chain ID: `31337`
   - Currency Symbol: `ETH`

2. **Import Test Account**:
   - Private Key: `0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6`
   - This account has ETH and is the contract owner

## 📋 Test Scenarios

### Scenario 1: Happy Path - Complete User Journey

#### Step 1: Initial Navigation
- [ ] Navigate to `http://localhost:3000`
- [ ] Verify "Welcome to Decentralized Option Vault" title
- [ ] Click "Launch DOV App 🚀" button
- [ ] Verify navigation to `/dov` page

#### Step 2: Wallet Connection
- [ ] Click "Connect Wallet" in MetaMask
- [ ] Verify wallet address displays correctly
- [ ] Check that all contract data loads (may show 0 initially)

#### Step 3: Get Test Tokens
- [ ] Click "Mint 1000 mETH" button
- [ ] Confirm transaction in MetaMask
- [ ] Wait for transaction confirmation
- [ ] Verify mETH balance increases to 1000

#### Step 4: Deposit to Vault
- [ ] Enter "100" in deposit amount field
- [ ] Click "Deposit" button
- [ ] Confirm approval transaction (first time)
- [ ] Confirm deposit transaction
- [ ] Verify:
  - mETH balance decreases by 100
  - Vault shares increase by 100
  - TVL shows 100 mETH
  - Share price remains 1.0000

#### Step 5: Strategy Roll (Yield Generation)
- [ ] Note current share price
- [ ] Click "🎯 Roll Strategy (Keeper)" button
- [ ] Confirm transaction
- [ ] Verify:
  - Strategy Active shows ✅
  - Button changes to "⏳ Wait for Next Cycle"
  - Time countdown appears

#### Step 6: Force Settlement (Testing)
*Note: This requires contract interaction via debug interface*
- [ ] Navigate to `/debug` page
- [ ] Find "MockStrategy" contract
- [ ] Call `forceSettle(0)` for OTM (profit) scenario
- [ ] Verify:
  - Share price increases to ~1.05
  - Total Yield shows positive value
  - Strategy Active shows ❌

#### Step 7: Withdraw Funds
- [ ] Enter "50" in withdraw shares field
- [ ] Click "Withdraw" button
- [ ] Confirm transaction
- [ ] Verify:
  - Vault shares decrease by 50
  - mETH balance increases by ~52.5 (if yield was generated)
  - TVL decreases proportionally

### Scenario 2: Edge Cases Testing

#### Test 2.1: Zero Amount Operations
- [ ] Try entering "0" in deposit field → Should show validation error
- [ ] Try entering "0" in withdraw field → Should show validation error
- [ ] Verify transactions don't execute

#### Test 2.2: Insufficient Balance
- [ ] Enter amount larger than mETH balance in deposit
- [ ] Attempt transaction → Should fail with insufficient balance
- [ ] Enter shares larger than owned in withdraw
- [ ] Attempt transaction → Should fail

#### Test 2.3: Premature Strategy Roll
- [ ] After rolling strategy, immediately try to roll again
- [ ] Should show "⏳ Wait for Next Cycle" and be disabled
- [ ] Verify countdown timer is accurate

#### Test 2.4: Withdraw During Active Strategy
- [ ] Roll strategy to make it active
- [ ] Try to withdraw large amount
- [ ] Should fail with "Insufficient liquid assets" error

### Scenario 3: Multi-User Testing

#### Setup Multiple Accounts
1. Import second test account or create new one
2. Send some ETH from main account for gas
3. Mint mETH for second account

#### Test 3.1: Proportional Yield Distribution
- [ ] Account A deposits 60 mETH
- [ ] Account B deposits 40 mETH
- [ ] Roll strategy and settle with profit
- [ ] Verify both accounts receive proportional yield:
  - Account A: 60% of total yield
  - Account B: 40% of total yield

### Scenario 4: Loss Scenario Testing

#### Test 4.1: ITM Settlement (Loss)
- [ ] Deposit funds and roll strategy
- [ ] Use debug interface to call `forceSettle(1)` (ITM)
- [ ] Verify:
  - Share price drops significantly (~0.05)
  - User loses ~95% of deposit
  - Total Yield may show negative

### Scenario 5: UI/UX Testing

#### Test 5.1: Responsive Design
- [ ] Test on mobile device/small screen
- [ ] Verify all buttons and inputs are accessible
- [ ] Check that layout adapts properly

#### Test 5.2: Real-time Updates
- [ ] Keep page open during transactions
- [ ] Verify metrics update automatically
- [ ] Check that pending states show correctly

#### Test 5.3: Error Handling
- [ ] Reject a transaction in MetaMask
- [ ] Verify error message displays
- [ ] Try transaction with insufficient gas
- [ ] Check error feedback

## 🔍 Verification Checklist

### Contract State Verification
- [ ] TVL calculation is accurate
- [ ] Share price reflects yield correctly
- [ ] User balances are consistent
- [ ] Strategy state transitions properly

### Frontend Functionality
- [ ] All buttons work as expected
- [ ] Input validation prevents invalid operations
- [ ] Transaction feedback is clear
- [ ] Loading states are appropriate

### Security Verification
- [ ] Cannot deposit/withdraw zero amounts
- [ ] Cannot withdraw more than owned
- [ ] Strategy timing restrictions work
- [ ] Access controls are enforced

## 🚨 Known Issues to Verify

### Expected Behaviors
1. **Rounding Errors**: May see 1 wei differences in calculations
2. **Gas Estimation**: Some transactions may require manual gas adjustment
3. **Timing**: Strategy rolls have 7-day minimum interval
4. **Randomness**: Outcomes are pseudo-random based on block timestamp

### Potential Issues
1. **MetaMask Connection**: May need to refresh page if connection fails
2. **Transaction Pending**: Wait for block confirmation before next action
3. **Contract Interaction**: Debug interface may be slow to load
4. **Browser Compatibility**: Test on Chrome/Firefox for best results

## 📊 Performance Testing

### Load Testing
- [ ] Perform 10+ consecutive deposits
- [ ] Monitor gas costs and transaction times
- [ ] Verify no memory leaks in frontend

### Stress Testing
- [ ] Test with maximum uint256 values (if possible)
- [ ] Rapid-fire transactions
- [ ] Multiple browser tabs

## 📈 Yield Verification

### Calculation Verification
```
Initial Deposit: 100 mETH
Premium Rate: 5%
Expected OTM Outcome: 105 mETH
Expected Share Price: 1.05
Expected ITM Outcome: 5 mETH
Expected Share Price: 0.05
```

### Manual Calculation
1. Note exact deposit amount
2. Note share price before strategy
3. Execute strategy and settlement
4. Calculate expected vs actual yield
5. Verify within acceptable tolerance (1 wei)

## 🎯 Success Criteria

### Minimum Viable Product
- [ ] Users can deposit and withdraw
- [ ] Strategy executes and generates yield
- [ ] All security measures work
- [ ] UI is functional and responsive

### Production Ready
- [ ] All edge cases handled gracefully
- [ ] Error messages are user-friendly
- [ ] Performance is acceptable
- [ ] Security is thoroughly tested

### Excellence Standard
- [ ] Zero critical bugs found
- [ ] Exceptional user experience
- [ ] Comprehensive error handling
- [ ] Professional-grade polish

## 📝 Test Results Documentation

### Test Execution Log
```
Date: ___________
Tester: ___________
Environment: ___________

Scenario 1 - Happy Path:
[ ] Step 1: _____ (Pass/Fail/Notes)
[ ] Step 2: _____ (Pass/Fail/Notes)
...

Issues Found:
1. _____________________
2. _____________________

Overall Assessment: ___________
```

### Bug Report Template
```
Bug ID: DOV-001
Severity: High/Medium/Low
Component: Frontend/Contract/Integration
Description: _____________________
Steps to Reproduce:
1. _____________________
2. _____________________
Expected Result: _____________________
Actual Result: _____________________
Browser/Environment: _____________________
```

---

**Testing Completion Target**: 100% scenarios verified
**Critical Path**: Scenario 1 (Happy Path) must pass completely
**Risk Assessment**: Document any security concerns found
**Performance Baseline**: Note gas costs and transaction times
