
# Kairos — AI-Driven Onchain Automations (DeFi Copilot)

**Kairos** is an AI-powered onchain automation framework that lets users create, manage, and execute blockchain workflows using natural language.  
Think of it as **“Zapier for DeFi”** — an AI copilot that turns your commands into autonomous smart contract actions.

## Overview

With Kairos, you can automate onchain actions like transfers based on price conditions — all through simple text.

Currently, the Sepolia deployment supports only PriceTrigger actions with ETH, DAI, LINK, and USDC.

### Example Commands

> “If ETH price reaches $2500 — send 0.1 ETH to this address.”
> “If DAI price drops below $0.99 — send 50 DAI to 0xAbC123...”

> **Note:** ReceiveTrigger and TimeTrigger are planned but not yet implemented.

The AI agent parses these intents and generates executable workflows stored on-chain.

## How It Works

### 1. **AI Interface Layer**
- User interacts via chat.
- The AI parses intent and outputs a structured JSON:

```json
{
  "trigger": {
    "type": "price",
    "asset": "ETH",
    "tokenAddress": "0x0000000000000000000000000000000000000000",
    "isGreaterThan": true,
    "value": 2500
  },
  "action": {
    "type": "transfer",
    "tokenAddress": "0x0000000000000000000000000000000000000000",
    "amount": 0.1,
    "recipient": "0xAbC123..."
  }
}
```

This JSON is sent to the frontend for submission to the smart contract.

### 2. **Backend / AI Middleware**

* Receives user messages from the frontend.
* Sends the user input to the AI agent.
* Receives the structured JSON response from the AI agent.
* Formats the JSON and returns it to the frontend.

### 3. **Smart Contract Layer (Solidity)**

* Stores workflow definitions on-chain (condition → action).
* Executes PriceTrigger actions deterministically when conditions fire.
* **Any user** can call `executeAction()` on behalf of another user; execution succeeds **only if conditions are met**.
* Execution fees are paid to the caller of `executeAction()`.
* Tracks user deposits per token.

**Current limitations:**
* ReceiveTrigger and TimeTrigger are placeholders (logic not yet implemented).
* Only ETH, DAI, LINK, USDC supported.

### 4. **Off-chain Agent / Oracle**

* Monitors onchain/offchain data via Chainlink price feeds.
* Calls `execute()` when conditions are met.
* Ensures reliable automation without constant onchain polling.

## Tech Stack

| Component          | Technology                         |
| ------------------ | ---------------------------------- |
| AI Parsing Layer   | asi1 agent                         |
| Smart Contracts    | Solidity (EVM-compatible networks) |
| Price Data         | Chainlink                          |
| Frontend           | Next.js + wagmi + RainbowKit       |
| Wallet Integration | MetaMask / WalletConnect           |


## Why Kairos?

* **No-code automation:** Create DeFi workflows by simply typing commands.
* **AI-native UX:** Natural language → smart contract execution.
* **Secure by design:** Onchain permission control for each agent.
* **Composability:** Plug-and-play with any EVM protocol or oracle.

## Potential Extensions

* **ReceiveTrigger & TimeTrigger** implementation.
* **Automation Marketplace** for reusable workflows.
* **DAO governance** for shared automation control.
* **AI-based portfolio balancing** and real-time strategies.

## Example Workflow (MVP Phase)

**Trigger:** ETH price ≥ $2500
**Action:** Send 0.1 ETH to `0xAbC123...`

**Flow:**

1. User submits command via frontend.
2. Backend sends the message to the AI agent.
3. AI agent parses it and returns structured JSON.
4. Backend formats and returns JSON to frontend.
5. Frontend allows user to submit the transaction to the smart contract.
6. Off-chain agent monitors conditions and executes `executeAction()` when triggered.

Contract Address: `0x6D2E351Ea84BF281237f1b512b0F5ddFA131acc2` (Sepolia)

## Architecture Diagram

```pgsql
+---------------------+
|         User        |
+----------+----------+
           |
           v
+----------+----------+
|   Frontend (Next.js)|
+----------+----------+
           |
           v
+----------+----------+
| Backend Middleware  |
|  (Node.js / Python) |
+----------+----------+
           |
           v
+----------+----------+
|      AI Agent       |
+----------+----------+
           |
           v
+----------+----------+
| Smart Contract (EVM)|
+----------+----------+
           |
           v
+----------+----------+
|  Off-chain Agent /  |
|     Chainlink       |
+---------------------+
```

> *Kairos bridges the gap between human intent and onchain execution — making DeFi truly autonomous.*

## License

[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)