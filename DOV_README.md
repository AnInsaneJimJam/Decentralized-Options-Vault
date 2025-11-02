# Decentralized Option Vault (DOV) - Covered Call Strategy

A complete implementation of a Decentralized Option Vault using Scaffold-ETH 2, featuring automated covered call strategies for yield generation.

## 🎯 Project Overview

This DOV implements a **single-asset, single-strategy Covered Call vault** that:
- Automatically accepts user collateral (mETH)
- Simulates selling covered call options weekly
- Generates yield through option premiums (5% per cycle)
- Uses ERC-4626 standard for vault shares
- Includes a complete frontend for user interaction

## 🏗️ Architecture

### Smart Contracts

1. **MockERC20.sol** - Test token (mETH) with minting capabilities
2. **CoveredCallVault.sol** - Main vault contract implementing ERC-4626
3. **MockStrategy.sol** - Simulates covered call option trading

### Key Features

- **ERC-4626 Compliance**: Standard vault interface for deposits/withdrawals
- **Automated Strategy**: Weekly cycles with keeper-triggered rolls
- **Risk Simulation**: Options can expire ITM (loss) or OTM (profit)
- **Yield Tracking**: Real-time performance metrics
- **Modern UI**: Clean, responsive interface built with Next.js

## 🚀 Quick Start

### Prerequisites
- Node.js >= 20.18.3
- Yarn package manager

### Setup & Run

1. **Install dependencies:**
   ```bash
   yarn install
   ```

2. **Start local blockchain:**
   ```bash
   yarn foundry:chain
   ```

3. **Deploy contracts:**
   ```bash
   yarn foundry:deploy
   ```

4. **Start frontend:**
   ```bash
   yarn start
   ```

5. **Access the app:**
   - Frontend: http://localhost:3000
   - DOV Interface: http://localhost:3000/dov

## 📋 Contract Addresses (Local)

- **MockERC20 (mETH)**: `0xa15bb66138824a1c7167f5e85b957d04dd34e468`
- **MockStrategy**: `0xb19b36b1456e65e3a6d514d3f715f204bd59f431`
- **CoveredCallVault**: `0x8ce361602b935680e8dec218b820ff5056beb7af`

## 🎮 How to Use

### 1. Get Test Tokens
- Click "Mint 1000 mETH" to get test tokens
- Connect your wallet (MetaMask recommended)

### 2. Deposit to Vault
- Enter amount of mETH to deposit
- Approve the transaction
- Receive vault shares representing your position

### 3. Strategy Management
- Wait for the weekly cycle (7 days) or use the keeper button
- Click "Roll Strategy" to execute the next option cycle
- Monitor your yield generation in real-time

### 4. Withdraw Funds
- Enter number of shares to redeem
- Withdraw your proportional share of vault assets

## 📊 Vault Mechanics

### Covered Call Strategy
1. **Deposit Phase**: Users deposit mETH, receive vault shares
2. **Option Sale**: Strategy sells covered calls, locks collateral
3. **Premium Collection**: Earns 5% premium on collateral
4. **Settlement**: 
   - **OTM (Out of Money)**: Keep collateral + premium = **Profit**
   - **ITM (In the Money)**: Lose collateral, keep premium = **Loss**
5. **Roll**: Repeat cycle weekly

### Risk & Reward
- **Expected Yield**: ~5% per week (if options expire OTM)
- **Risk**: Potential loss of collateral if options expire ITM
- **Diversification**: Single-asset strategy (can be extended)

## 🧪 Testing

Run the comprehensive test suite:

```bash
yarn foundry:test
```

### Test Coverage
- ✅ Deposit/Withdraw functionality
- ✅ Strategy roll mechanics
- ✅ Option outcome simulation
- ✅ Vault metrics calculation
- ✅ ERC-4626 compliance

## 🔧 Technical Details

### ERC-4626 Implementation
- Standard vault interface for maximum compatibility
- Automatic share price calculation based on total assets
- Proportional yield distribution to all shareholders

### Strategy Simulation
- Mock premium generation through token minting
- Pseudo-random option outcomes for demonstration
- Configurable premium rates (default: 5%)

### Frontend Features
- Real-time vault metrics display
- Transaction status feedback
- Responsive design for mobile/desktop
- Integration with Scaffold-ETH hooks

## 🛠️ Development

### Project Structure
```
packages/
├── foundry/           # Smart contracts & deployment
│   ├── contracts/     # Solidity contracts
│   ├── script/        # Deployment scripts
│   └── test/          # Contract tests
└── nextjs/           # Frontend application
    ├── app/          # Next.js app router
    ├── components/   # React components
    └── hooks/        # Web3 hooks
```

### Key Commands
- `yarn foundry:compile` - Compile contracts
- `yarn foundry:test` - Run tests
- `yarn foundry:deploy` - Deploy to local chain
- `yarn start` - Start development server

## 🎯 Hackathon Ready

This project is designed for **2-3 hour hackathon implementation** with:

- ✅ **Core Functionality**: Complete vault with yield generation
- ✅ **Demo Ready**: Working frontend with all features
- ✅ **Well Tested**: Comprehensive test suite
- ✅ **Professional UI**: Clean, modern interface
- ✅ **Documentation**: Complete setup and usage guide

## 🚀 Future Enhancements

### Phase 4+ Extensions
- Multiple asset support (ETH, BTC, etc.)
- Real options integration (Lyra, Hegic)
- Advanced strategies (puts, straddles)
- Governance token and DAO
- Cross-chain deployment
- Performance analytics dashboard

## 📝 License

MIT License - See LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

---

**Built with ❤️ using Scaffold-ETH 2**

*This project demonstrates the power of decentralized finance through automated yield strategies. Perfect for hackathons, learning, and building the future of DeFi.*
