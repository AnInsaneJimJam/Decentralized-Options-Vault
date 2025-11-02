# DOV System Flowchart - Complete Interaction Flow

## 🎯 High-Level System Overview

```mermaid
graph TB
    subgraph "👥 Actors"
        USER[👤 User]
        KEEPER[🤖 Keeper]
        OWNER[👑 Owner]
    end

    subgraph "🏦 Core Contracts"
        TOKEN[📄 MockERC20<br/>mETH Token]
        VAULT[🏛️ CoveredCallVault<br/>ERC-4626 Vault]
        STRATEGY[⚡ MockStrategy<br/>Options Simulator]
    end

    subgraph "💾 State"
        SHARES[📊 User Shares]
        TVL[💰 Total Value Locked]
        YIELD[📈 Generated Yield]
    end

    USER --> TOKEN
    USER --> VAULT
    KEEPER --> VAULT
    OWNER --> STRATEGY
    VAULT --> STRATEGY
    STRATEGY --> TOKEN
    VAULT --> SHARES
    VAULT --> TVL
    STRATEGY --> YIELD

    classDef actor fill:#e3f2fd
    classDef contract fill:#f3e5f5
    classDef state fill:#e8f5e8

    class USER,KEEPER,OWNER actor
    class TOKEN,VAULT,STRATEGY contract
    class SHARES,TVL,YIELD state
```

## 🔄 Detailed Function Flow

### **1. Token Management Flow**

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant T as 📄 MockERC20
    participant V as 🏛️ Vault

    Note over U,V: Phase 1: Get Test Tokens
    U->>T: mintToSelf(1000 mETH)
    T-->>U: ✅ Tokens minted
    
    Note over U,V: Phase 2: Approve Vault
    U->>T: approve(vault, 100 mETH)
    T-->>U: ✅ Approval granted
    
    Note over U,V: Phase 3: Check Balance
    U->>T: balanceOf(user)
    T-->>U: 1000 mETH
```

### **2. Deposit & Share Management Flow**

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant V as 🏛️ Vault
    participant T as 📄 MockERC20

    Note over U,T: User Deposit Process
    U->>V: deposit(100 mETH, user)
    V->>V: require(assets > 0)
    V->>T: transferFrom(user, vault, 100)
    V->>V: _mint(user, 100 shares)
    V-->>U: ✅ 100 shares received
    
    Note over U,T: Check Vault State
    U->>V: balanceOf(user)
    V-->>U: 100 shares
    U->>V: totalAssets()
    V-->>U: 100 mETH
    U->>V: sharePrice()
    V-->>U: 1.0000
```

### **3. Strategy Activation Flow**

```mermaid
sequenceDiagram
    participant K as 🤖 Keeper
    participant V as 🏛️ Vault
    participant S as ⚡ Strategy
    participant T as 📄 MockERC20

    Note over K,T: Strategy Roll Process
    K->>V: rollStrategy()
    V->>V: require(time >= lastRoll + 7 days)
    
    Note over V,T: Send Assets to Strategy
    V->>T: approve(strategy, 100 mETH)
    V->>S: depositCollateral(100 mETH)
    S->>T: transferFrom(vault, strategy, 100)
    
    Note over V,T: Execute Option Sale
    V->>S: executeOptionSale(100 mETH)
    S->>S: currentPremium = 100 * 5% = 5 mETH
    S->>T: mint(strategy, 5 mETH) // Simulate premium
    S->>S: hasActivePosition = true
    V->>V: strategyActive = true
    
    V-->>K: ✅ Strategy activated
```

### **4. Settlement & Yield Generation Flow**

```mermaid
sequenceDiagram
    participant K as 🤖 Keeper
    participant V as 🏛️ Vault
    participant S as ⚡ Strategy
    participant T as 📄 MockERC20

    Note over K,T: Settlement Process (OTM Scenario)
    K->>V: rollStrategy() // After 7 days
    V->>S: settleTrade()
    
    Note over S,T: Determine Outcome
    S->>S: optionStatus = random(0,1)
    S->>S: if (optionStatus == 0) // OTM
    S->>S: assetsToReturn = 100 + 5 = 105 mETH
    
    Note over S,T: Return Assets + Yield
    S->>T: transfer(vault, 105 mETH)
    S->>S: hasActivePosition = false
    S-->>V: return 105
    
    Note over V,T: Update Vault State
    V->>V: totalYieldGenerated += 5
    V->>V: sharePrice = 105/100 = 1.05
    V-->>K: ✅ Yield generated: 5 mETH
```

### **5. Withdrawal Flow**

```mermaid
sequenceDiagram
    participant U as 👤 User
    participant V as 🏛️ Vault
    participant T as 📄 MockERC20

    Note over U,T: User Withdrawal Process
    U->>V: redeem(50 shares, user, user)
    V->>V: require(shares > 0)
    V->>V: assets = convertToAssets(50) = 52.5 mETH
    V->>V: _burn(user, 50 shares)
    V->>T: transfer(user, 52.5 mETH)
    V-->>U: ✅ 52.5 mETH received (2.5 profit!)
```

## 📋 Complete State Machine

```mermaid
stateDiagram-v2
    [*] --> Deployed: Deploy Contracts
    
    state "Vault States" as VS {
        Deployed --> Inactive: Initial State
        Inactive --> Active: rollStrategy()
        Active --> Inactive: settleTrade()
        Active --> Emergency: emergencySettle()
        Emergency --> Inactive: Resume
    }
    
    state "Strategy States" as SS {
        NoPosition --> ActivePosition: executeOptionSale()
        ActivePosition --> NoPosition: settleTrade()
        ActivePosition --> Forced: forceSettle()
        Forced --> NoPosition: Complete
    }
    
    state "User States" as US {
        NoShares --> HasShares: deposit()
        HasShares --> MoreShares: deposit()
        HasShares --> FewerShares: withdraw()
        FewerShares --> NoShares: withdraw(all)
    }
```

## 🎮 Function Call Hierarchy

```mermaid
graph TD
    subgraph "User Functions"
        UF1[mintToSelf]
        UF2[deposit]
        UF3[withdraw/redeem]
        UF4[balanceOf]
    end

    subgraph "Keeper Functions"
        KF1[rollStrategy]
    end

    subgraph "Owner Functions"
        OF1[setStrategy]
        OF2[setPremiumRate]
        OF3[forceSettle]
        OF4[emergencySettle]
    end

    subgraph "Internal Calls"
        IC1[depositCollateral]
        IC2[executeOptionSale]
        IC3[settleTrade]
        IC4[getAssetsToReturn]
    end

    subgraph "View Functions"
        VF1[totalAssets]
        VF2[sharePrice]
        VF3[getVaultMetrics]
        VF4[canRollStrategy]
    end

    UF1 --> TOKEN
    UF2 --> VAULT
    UF3 --> VAULT
    UF4 --> VAULT

    KF1 --> VAULT
    KF1 --> IC1
    KF1 --> IC2
    KF1 --> IC3

    OF1 --> VAULT
    OF2 --> STRATEGY
    OF3 --> STRATEGY
    OF4 --> VAULT

    IC1 --> STRATEGY
    IC2 --> STRATEGY
    IC3 --> STRATEGY
    IC4 --> STRATEGY

    VF1 --> VAULT
    VF2 --> VAULT
    VF3 --> VAULT
    VF4 --> VAULT

    classDef userFunc fill:#e3f2fd
    classDef keeperFunc fill:#fff3e0
    classDef ownerFunc fill:#fce4ec
    classDef internalFunc fill:#f1f8e9
    classDef viewFunc fill:#f3e5f5

    class UF1,UF2,UF3,UF4 userFunc
    class KF1 keeperFunc
    class OF1,OF2,OF3,OF4 ownerFunc
    class IC1,IC2,IC3,IC4 internalFunc
    class VF1,VF2,VF3,VF4 viewFunc
```

## 🔄 Data Flow Architecture

```mermaid
graph LR
    subgraph "Input Layer"
        I1[User Deposits]
        I2[Keeper Triggers]
        I3[Owner Commands]
    end

    subgraph "Processing Layer"
        P1[Vault Logic]
        P2[Strategy Logic]
        P3[Token Operations]
    end

    subgraph "Storage Layer"
        S1[Share Balances]
        S2[Asset Balances]
        S3[Strategy State]
        S4[Yield Tracking]
    end

    subgraph "Output Layer"
        O1[Share Tokens]
        O2[Yield Generation]
        O3[Metrics Display]
    end

    I1 --> P1
    I2 --> P1
    I3 --> P2
    
    P1 --> P3
    P1 --> P2
    P2 --> P3
    
    P1 --> S1
    P2 --> S3
    P3 --> S2
    P1 --> S4
    
    S1 --> O1
    S4 --> O2
    S1 --> O3
    S2 --> O3
    S3 --> O3

    classDef input fill:#e8f5e8
    classDef process fill:#fff3e0
    classDef storage fill:#f3e5f5
    classDef output fill:#e3f2fd

    class I1,I2,I3 input
    class P1,P2,P3 process
    class S1,S2,S3,S4 storage
    class O1,O2,O3 output
```

## 🎯 Key Integration Points

### **Contract Interfaces:**
1. **Vault ↔ Strategy**: `depositCollateral()`, `executeOptionSale()`, `settleTrade()`
2. **Vault ↔ Token**: `transfer()`, `approve()`, `transferFrom()`
3. **Strategy ↔ Token**: `mint()`, `transfer()` (for premium simulation)

### **State Synchronization:**
1. **strategyActive** (Vault) ↔ **hasActivePosition** (Strategy)
2. **totalAssets()** (Vault) includes **getAssetsToReturn()** (Strategy)
3. **sharePrice** reflects accumulated **totalYieldGenerated**

### **Access Control:**
1. **onlyVault** modifier protects strategy functions
2. **onlyOwner** modifier protects admin functions
3. **nonReentrant** modifier protects state-changing functions

This architecture ensures clean separation of concerns while maintaining tight integration for seamless operation.
