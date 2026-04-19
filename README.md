# MeshChain: A Blockchain-based Incentive Framework for crowdsourced Mesh and Ad Hoc Networks

Smart contracts for **MeshChain**, a blockchain-based framework that guarantees **fair, trusted, and transparent payments** to mesh routers in commercialized mesh networks.

This repository contains the **on-chain components** (Solidity smart contracts) that implement the blockchain part of the framework described in the paper:

> **“MeshChain: A Comprehensive Blockchain-based Framework for Mesh Networks”**

---

## Overview

Commercial mesh networks rely on users allowing their devices to act as **mesh routers**, forwarding traffic for others. To make this sustainable at scale, we need:

- **Guaranteed payments** to routers that actually forward traffic,
- **Fairness**, so rewards reflect each router’s real contribution,
- **Transparency and trust**, without a central payment authority.

**MeshChain** uses Ethereum smart contracts to:

- Manage mesh user / router registration and reputation,
- Handle routing requests and funding,
- Collect validator decisions on routing behavior,
- Compute and distribute crypto-token payments based on **Proof of Routing (PoR)**.

Routing itself and detailed logging happen **off-chain**, while coordination, validation outcomes, and payments are performed **on-chain**.

---

## From MeshChain Paper

Mesh networks provide decentralized connectivity for homes, enterprises, and wider deployments. Extending these networks to commercial use requires **incentive mechanisms** for mesh routers. While previous work has explored cryptocurrency-based rewards, open challenges remain in:

- Managing payments,
- Considering routing cost during router selection,
- Validating routing actions to guarantee **fair payment**.

MeshChain proposes a **comprehensive blockchain-based framework** in which:

- Routing requests, routing validation, PoR-based consensus, and payments are handled **on-chain**, and  
- High-quality, cost-effective routers are selected **off-chain** based on quality, reputation, and cost.

Routing data is stored in tamper-proof logs, shared with trusted validators. Validators analyze these logs and submit decisions to the blockchain, where a **Proof of Routing** consensus is established. Payments are then computed and issued according to each router’s performance and contribution. Simulation results show the feasibility of the proposed framework.

---

## Repository Contents

### `userManager.sol`

**Contract:** `MeshUsers`  
**Role:** Manages mesh participants (routers/users) and their performance profile.

- Assigns a unique `userID` to each address.
- Tracks:
  - **Reputation**,
  - **Total bytes forwarded**,
  - **Average delay**,
  - **Total traffic/requests served**.
- Provides helper functions to query and update user statistics.
- Emits events when users are added, deleted, or their stats change.

This contract is intended to supply **input to the off-chain router selection logic** (e.g., quality- and reputation-aware routing).

### `MeshServiceManager.sol`

**Contract:** `MeshServiceManager`  
**Role:** Manages deposits, routing requests, validator decisions, PoR aggregation, and payments.

- Maintains **deposits** for each address (funds used to pay routers).
- Lets users:
  - Deposit and withdraw Ether,
  - Create routing requests with a specified destination and requested bytes,
  - End a service session.
- Stores **validator decisions** about routers’ behavior (bytes forwarded, packet forwarding percentage, routing cost).
- Aggregates decisions using a **majority-vote scheme** (Proof of Routing).
- Computes and assigns payments from requesters to routers based on:
  - Bytes transmitted,
  - Packet forwarding percentage,
  - Reported routing cost.

---

## Basic Workflow

At a high level, MeshChain is used as follows:

1. **User / Router registration**
   - Mesh routers are registered in `MeshUsers` and assigned a `userID`.
   - Their reputation and statistics are updated over time based on performance.

2. **Funding**
   - A requester deposits Ether into `MeshServiceManager` via `deposit()`.

3. **Routing Request**
   - The requester calls `requestService(...)` to create a routing request (destination, bytes, IP info).
   - The request is stored on-chain and assigned a `requestID`.

4. **Off-chain Routing & Validation**
   - An off-chain routing algorithm (e.g., cost-based QoS-OLSR) selects routers.
   - Routers forward packets and log routing behavior in tamper-proof logs.
   - Validators analyze these logs and submit decisions to `MeshServiceManager` using `addDecision(...)` (and `addHeadDecision2(...)` for head routers).

5. **Proof of Routing & Payment**
   - Once enough decisions are collected (e.g., 3 per router/request), the contract:
     - Aggregates them via majority voting,
     - Computes a payment based on bytes forwarded, packet delivery, and cost,
     - Transfers funds between internal deposits of the requester and the router.
   - Routers can later withdraw earnings using `withdraw(amount)`.

---

## Getting Started

You can integrate these contracts into any Solidity/EVM toolchain (Hardhat, Foundry, Truffle, etc.). Below is a generic workflow.

## Citing MeshChain

If you use MeshChain or these smart contracts in academic work, please cite:

MeshChain: A Comprehensive Blockchain-based Framework for Mesh Networks
H Abualola, R Mizouni, S Singh, H Otrok - Ad Hoc Networks, 2025
doi: https://doi.org/10.1016/j.adhoc.2025.103860
