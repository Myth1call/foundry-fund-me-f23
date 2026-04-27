# FundMe (Solidity + Foundry)

**FundMe** is a minimal yet realistic example of decentralized crowdfunding on Ethereum.  
This project demonstrates how to use Solidity, Foundry, and Chainlink to build a contract that:

- **accepts ETH funding**;
- **enforces a minimum USD contribution** via Chainlink price feeds;
- **allows only the contract owner** to withdraw collected funds;
- demonstrates **gas-optimized** withdrawal patterns.

It is based on the Cyfrin smart contract development course.

---

## Core Idea

Traditional crowdfunding platforms are centralized and control user funds.  
**FundMe** implements a simple decentralized model:

- any user can fund the contract with ETH;
- a contribution is accepted only if its value is \(\ge 5\) USD (based on Chainlink ETH/USD);
- the contract owner can withdraw all accumulated funds;
- contributions and funder addresses are tracked in contract state.

---

## Project Architecture

- `src/FundMe.sol`  
  - main smart contract;  
  - stores:
    - `s_addressToAmountFunded` - mapping address -> funded amount;
    - `s_funders` - array of all funder addresses;  
  - key functions:
    - `fund()` - contribute funds (with min USD check);
    - `withdraw()` - standard owner-only withdrawal;
    - `cheaperWithdraw()` - gas-optimized withdrawal;
    - `getAddressToAmountFunded`, `getFunder`, `getOwner`, `getVersion`;  
  - `MINIMUM_USD = 5e18` - minimum contribution in USD (via Chainlink price feed).

- `src/PriceConverter.sol`  
  - library for Chainlink `AggregatorV3Interface`;  
  - `getPrice()` - fetches current ETH/USD price;  
  - `getConversionRate()` - converts `ethAmount` to USD equivalent (18 decimals).

- `script/HelperConfig.s.sol`  
  - network-specific configuration:
    - uses real Sepolia ETH/USD feed `0x694AA1769357215DE4FAC081bf1f309aDC325306`;
    - for local Anvil, deploys `MockV3Aggregator` and returns its address;  
  - selects configuration by `block.chainid`.

- `script/DeployFundMe.s.sol`  
  - deployment script for `FundMe`;  
  - gets active network config from `HelperConfig`;  
  - calls `FundMe(priceFeed)` constructor.

- `script/Interactions.s.sol`  
  - `FundFundMe` script:
    - finds the **most recent deployment** of `FundMe` via `DevOpsTools.get_most_recent_deployment`;
    - calls `fund{value: 0.1 ether}()` on that contract;
  - `WithdrawFundMe` script:
    - finds the most recent `FundMe` deployment;
    - calls `withdraw()` to send balance to owner.

- `test/FundMe.t.sol`  
  - unit tests for `FundMe`:
    - verifies `MINIMUM_USD`;
    - verifies owner setup;
    - verifies price feed version;
    - reverts when ETH sent is insufficient;
    - updates contribution storage correctly;
    - restricts withdrawals to owner;
    - tests withdrawal with one and many funders (both `withdraw` and `cheaperWithdraw`).

- `test/Interactions.t.sol`  
  - integration test:
    - deploys `FundMe`;
    - user (Karina) funds with `SEND_VALUE = 0.1 ether`;
    - owner withdraws funds;
    - verifies final balances of user, owner, and contract.

- `Makefile`  
  - `build` - `forge build`;  
  - `deploy-sepolia` - deploys to Sepolia via `forge script` and verifies on Etherscan.

---

## Tech Stack

- **Solidity 0.8.x** - smart contract language.  
- **Foundry** (`forge`, `cast`, `anvil`) - build, test, local blockchain.  
- **Chainlink** - decentralized ETH/USD price feeds.  
- **foundry-devops** - utilities for working with latest deployments.  
- **Makefile** - convenient build/deploy commands.

---

## Installation and Setup

1. **Clone repository**

```bash
git clone <YOUR_REPOSITORY_URL> foundry-fund-me-f23
cd foundry-fund-me-f23
```

2. **Install Foundry** (if not installed yet)

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

3. **Install dependencies (if needed)**

```bash
forge install
```

4. **Create and fill `.env`**

Example:

```bash
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/<YOUR_INFURA_KEY>
SEPOLIA_PRIVATE_KEY=0x<YOUR_PRIVATE_KEY>
ETHERSCAN_API_KEY=<YOUR_ETHERSCAN_API_KEY>
```

> **Important:** never commit your private key to a public repository.

---

## Main Commands

Run all commands from project root.

- **Build contracts**

```bash
forge build
# or
make build
```

- **Run tests**

```bash
forge test
```

With more verbose output:

```bash
forge test -vvv
```

With gas report:

```bash
forge test --gas-report
```

---

## Local Development (Anvil)

1. Start local node:

```bash
anvil
```

2. In another terminal (optionally with `--rpc-url`):

```bash
forge script script/DeployFundMe.s.sol:DeployFundMe \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --broadcast -vvvv
```

`HelperConfig` automatically:

- detects this is not Sepolia;
- deploys `MockV3Aggregator`;
- passes its address into `FundMe` constructor.

3. Then you can run interaction scripts (`Interactions.s.sol`) similarly (see below).

---

## Deploy to Sepolia

To deploy to Sepolia via `Makefile` (using `.env`):

```bash
make deploy-sepolia
```

This command:

- runs `forge script script/DeployFundMe.s.sol:DeployFundMe`;
- uses `SEPOLIA_RPC_URL`, `SEPOLIA_PRIVATE_KEY`;
- enables `--broadcast` and `--verify` (Etherscan verification);
- logs verbose output (`-vvvv`).

---

## Interacting with an Already Deployed Contract

Scripts in `script/Interactions.s.sol` use `DevOpsTools.get_most_recent_deployment`, so:

1. First deploy (`DeployFundMe`) to create latest deployment records for current chain.
2. Then call:

- **Fund contract (0.1 ETH)**

```bash
forge script script/Interactions.s.sol:FundFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast -vvvv
```

- **Withdraw funds (owner)**

```bash
forge script script/Interactions.s.sol:WithdrawFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast -vvvv
```

Scripts will:

- automatically resolve the latest `FundMe` deployment on target chain;
- execute `fund()` or `withdraw()` transactions.

---

## Smart Contract Behavior

- **Minimum contribution**  
  `fund()` does `require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD)`.  
  If the sent amount is too small, it reverts with `"You need to spend more ETH!"`.

- **Funder accounting**  
  On successful `fund()`:
  - `s_addressToAmountFunded[msg.sender]` increases by `msg.value`;
  - `msg.sender` is added to `s_funders`.

- **Withdrawals**  
  `withdraw()` and `cheaperWithdraw()`:

  - reset all entries in `s_addressToAmountFunded`;
  - clear `s_funders`;
  - transfer full contract balance to owner (`i_owner`) via low-level `call`.

  Difference: `cheaperWithdraw()` copies funders array to memory to reduce gas.

- **Fallback / receive**  
  If ETH is sent directly (without calling `fund()`), `receive()` or `fallback()` triggers and calls `fund()` internally.  
  This preserves minimum contribution and funder accounting logic.

---

## Testing

Tests use Foundry cheatcodes (`vm`, `hoax`, `prank`, etc.) to emulate:

- different senders;
- initial balances;
- multi-funder scenarios;
- expected reverts.

Recommended to run regularly:

```bash
forge test --gas-report
```

to monitor gas impact after changes.
