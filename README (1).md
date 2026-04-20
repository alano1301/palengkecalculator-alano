# TilapiaFarm Supply Chain Smart Contract

**Student:** Alano, Prince Russel  
**Course:** BSIT-4A  
**Exam:** Midterm Exam – Part 1  

---

## Selected Farm Business

**Tilapia Farming** — one of the most common aquaculture businesses in the Philippines,
involving the harvest, packaging, and distribution of fresh or processed tilapia fish.

---

## Description of System

This smart contract tracks the full lifecycle of tilapia farm products on the Ethereum
blockchain — from the moment a farmer registers a product, through transfer to a
distributor, all the way to delivery confirmation.

The system guarantees:
- **Transparency** — all transactions are recorded on-chain and publicly viewable
- **Traceability** — full ownership history per product
- **Data Integrity** — only authorized roles can perform actions; status flows
  are strictly enforced

---

## Contract Features

| Feature | Description |
|---|---|
| Role Management | Admin assigns Farmer / Distributor roles |
| Product Registration | Farmer registers product with name, quantity, origin, price |
| Ownership Tracking | Tracks current owner; records every transfer |
| Status Updates | Created (0) → In Transit (1) → Delivered (2) |
| Transfer Function | Transfers ownership and auto-updates status |
| Access Control | Only Farmers register; only Distributors confirm delivery |
| Data Retrieval | View product details, ownership history, current status |
| Batch Tracking *(Bonus)* | Transfer multiple products in one transaction |
| Price Tracking *(Bonus)* | Farmer can update product price before delivery |
| Payment Simulation *(Bonus)* | Distributor can send ETH payment to farmer on delivery |

---

## Status Table

| Number | Status | Triggered By |
|--------|--------|--------------|
| 0 | Created | `registerProduct()` |
| 1 | In Transit | `transferToDistributor()` or `batchTransferToDistributor()` |
| 2 | Delivered | `confirmDelivery()` |

---

## Sample Test Steps (Remix)

### Setup
1. Deploy contract using **Account 1** (becomes Admin + Farmer)
2. Copy **Account 2** address → call `assignRole(Account2, 2)` → makes it a Distributor

### Product Creation
3. Using Account 1, call: