# MasterEconomics: Deep-Dive Macro-Economic Architecture Proposal

## 1. Executive Summary

This document serves as the comprehensive architectural blueprint for the MasterEconomics application. Our objective is to transition from a micro-simulation of individuals with static integer balances into a **Macro-Economic Banking Simulator**. 

By rooting our software architecture directly in classical economic philosophy—specifically Henry Dunning Macleod’s *Principles of Economical Philosophy*—we can create a double-entry ledger system capable of accurately modeling complex modern financial realities. Whether it is a consumer swiping a credit card, a commercial bank discounting a promissory note to the Federal Reserve, or a FinTech company operating an FBO (For Benefit Of) custody layer, our core abstraction relies on the premise that **Credit is a first-class, exchangeable asset**.

## 2. The Classical Economic Foundation

Our system rejects the colloquial definitions of economic terms in favor of strict, mathematically sound classical definitions.

### 2.1. Wealth and Exchangeability
In colloquial terms, "wealth" often implies physical material. However, Macleod, citing the Pandects of Justinian and ancient Roman Law, establishes that the singular defining characteristic of Wealth is **Exchangeability**.
*   *Citation:* "The ancients held that the principle of Wealth lies exclusively in Exchangeability, and that whatever is Exchangeable is Wealth... an Economic Quantity must be one of three forms: Money, Labour, or Credit." (Macleod, Vol. 1, Chap. IV. § 11).

In our system, anything that can be bought or sold is an `Economic Quantity`.

### 2.2. The True Meaning of Production and Consumption
Our models explicitly divorce "Production" from the physical creation of matter, and "Consumption" from physical destruction.
*   *Citation:* "To Produce in Economics means to bring forward and offer for sale... To Consume in Economics means to purchase: the Consumer is the Customer." (Macleod, Vol. 1, Chap. IV. § 33).

Therefore, our `Exchangeable` concern simply tracks the offering (`produce!`) and purchasing (`consume!`) of assets in the marketplace.

### 2.3. Credit as Incorporeal Wealth
The most crucial paradigm shift in our software is the treatment of Credit. Credit is not merely an integer denoting purchasing capacity (e.g., `@available_credit = 500`); it is **Incorporeal Wealth**—a distinct entity created out of thin air by mutual consent.
*   *Citation:* "Credit is in Economics what Gravity is in Mechanics... Rights are Wealth." (Macleod, Vol. 1, Chap. IV. § 16).

### 2.4. The Duality of Debt (The Contract)
When Credit is instantiated, it exists as a `Contract`. This contract creates two inverse quantities mathematically:
*   *Citation:* "Contract includes the Right to Demand and the Duty to Pay... If the Right to demand be Positive, the Duty to pay is Negative." (Macleod, Vol. 1, Chap. VII. § 13-18).
To the Creditor, it is an Asset (`Right of Action`). To the Debtor, it is a Liability (`Duty to Pay`).

## 3. The Database Schema: A Pure Ledger of Facts

To support this philosophy, the database must not attempt to calculate dynamic limits; it must act purely as an immutable ledger of macroeconomic facts. This mirrors the `schema_planning.md` structure.

### 3.1. The Registry Layer
Lookup tables that define the taxonomy of the economy.
*   `instrument_registry`: Defines the type of contract (e.g., 10=Promissory Note, 20=Bond).
*   `maturity_registry`: Defines the duration intent (e.g., 1=On Demand, 2=Fixed Date).
*   `account_direction_registry`: Defines the mathematical sign of the ledger entry (1=Right of Action [+], 2=Duty to Pay [-]).

### 3.2. The Identity Layer
*   `actors`: The legal entities operating in the macro-economy (Governments, Central Banks, Commercial Banks, Corporations).

### 3.3. The Hub & The Ledger
*   `financial_recordings`: The metadata hub. When a contract is signed, it creates a recording linking the instrument to the creator.
*   `ledger_entries`: The raw double-entry lines. A single `financial_recording` generates two `ledger_entries`—one conferring the `Right of Action` to the creditor, and one conferring the `Duty to Pay` to the debtor.

### 3.4. Scenario 1: The SEC Filing (Macro-View of Debt)
*   **The Reality:** Apple Inc. files a 10-K stating they have issued $10 Billion in corporate bonds.
*   **The System Model:** We don't need to know who bought every bond. We instantiate an `Actor` for Apple. We create a `FinancialRecording` for a `Bond`. We insert a `LedgerEntry` for Apple where `direction = 2 (Duty to Pay)` and `value = 10,000,000,000`. The corresponding `Right of Action` can be assigned to a generic "Public Market" `Actor` until purchased by a specific bank.

## 4. The Ruby Application Architecture

### 4.1. Core Models
*   **`Actor`**: Replaces the isolated `Consumer` and `Debtor` models. An `Actor` has many `ledger_entries`. We dynamically calculate their `net_worth` by summing their Cash and `Rights of Action`, then subtracting their `Duties to Pay`.
    *   **The `Consumer` Role:** The concept of a Consumer survives as a *role* an Actor plays when placing `Bids` in the market, allowing us to measure aggregate Demand.
*   **`Contract` (Instruments)**: Subclasses like `PromissoryNote` and `Bond`. These are the actual ActiveRecord models that represent the Incorporeal Wealth.

### 4.2. Concerns (Behaviors)
*   **`Recordable`**: Attached to Instruments. Hook: `after_create :generate_ledger_entries!`. This ensures the double-entry accounting is perfectly maintained upon the instantiation of any debt.
*   **`Exchangeable`**: Allows an Actor to offer a `Right of Action` for sale (`produce!`) and another Actor to buy it (`consume!`). Buying simply updates the `party_id` on the `Right of Action` ledger entry, transferring the wealth.
*   **`Capitalizable`**: Tracks the velocity of capital. Calculates the **Annualized Rate of Profit** by factoring in `T_days` (duration held) and the discount price paid for the debt.

## 5. Real-World Scenarios & System Workflows

How does this theoretical architecture map to daily life and complex finance?

### 5.1. Scenario 2: Modern Retail Point-of-Sale (The Credit Card)
*   **The Reality:** A Consumer buys $100 of groceries with a Visa card. The Grocery Store gets cash immediately; the Consumer owes the Bank.
*   **The System Model:**
    1. The `Consumer` (Actor) places a bid for groceries.
    2. The transaction triggers a pre-existing Revolving Credit Agreement.
    3. The system generates a `FinancialRecording` (Credit Card Charge).
    4. `LedgerEntries` created:
       * Grocery Store: +$100 Cash.
       * Bank: +$100 `Right of Action` against Consumer.
       * Consumer: -$100 `Duty to Pay` Bank.
    *   *Result:* The merchant is removed from the debt chain entirely, matching modern mechanics perfectly.

### 5.2. Scenario 3: Bank Discounting and Securitization
*   **The Reality:** A Commercial Bank has issued thousands of mortgages (Rights of Action). They need liquidity, so they bundle them into a Mortgage-Backed Security (MBS) and sell it to the Federal Reserve.
*   **The System Model:**
    1. The Bank aggregates its `Right of Action` ledger entries.
    2. It uses the `Exchangeable` concern to `produce!` an MBS Contract at a slight discount.
    3. The Federal Reserve uses `consume!` to buy it.
    4. The `party_id` on the underlying `Rights of Action` shifts to the Fed. The Bank receives liquid Cash.
    5. The Fed uses `Capitalizable` to calculate its yield over the 30-year maturity.

### 5.3. Scenario 4: FinTech Intermediaries (PayPal / FBO Accounts)
*   **The Reality:** Users "deposit" money in PayPal, but PayPal places the aggregate funds into a Wells Fargo FBO account. Users have a claim against PayPal, not Wells Fargo.
*   **The System Model:**
    1. `Actor` (Wells Fargo) holds `Duty to Pay` to `Actor` (PayPal).
    2. `Actor` (PayPal) holds `Right of Action` against Wells Fargo.
    3. `Actor` (User) holds `Right of Action` against PayPal.
    4. `Actor` (PayPal) holds `Duty to Pay` to User.
    *   *Result:* Our system natively exposes the systemic counterparty risk without needing custom code. If Wells Fargo fails, PayPal's Asset vanishes, but its Liability to the User remains.

## 6. Integrating Real-World Data Feeds

The true power of this architecture is its ability to ingest real daily data to drive the simulation, transitioning it from a game into a macroeconomic analytical tool.

1.  **Cost of Capital (The Hurdle Rate):**
    *   *Source:* **FRED API** (Federal Reserve Economic Data) - Series: DPCREDIT (Discount Window Primary Credit Rate).
    *   *Usage:* Sets the baseline `System.cost_of_capital`. Simulated Banks will not `consume!` discounted debt if the calculated `annualized_rate_of_profit` is below this real-world hurdle rate.
2.  **Corporate Liabilities:**
    *   *Source:* **SEC EDGAR / xBRL APIs**.
    *   *Usage:* Rake tasks parse corporate 10-Ks to programmatically instantiate `PromissoryNote` and `Bond` recordings, populating the ledger with exact, real-world `Duties to Pay` for public companies.
3.  **Bank Loan Portfolios:**
    *   *Source:* **FDIC Call Reports**.
    *   *Usage:* We ingest these massive balance sheets to seed `Bank` Actors with accurate aggregate `Rights of Action` representing the outstanding US credit supply.
4.  **Consumer Debt Ceilings:**
    *   *Source:* **Federal Reserve Board G.19 (Consumer Credit)**.
    *   *Usage:* Sets the macroeconomic ceiling on how many retail `FinancialRecordings` our simulated `Consumers` can generate per cycle.

## 7. Execution Roadmap

To realize this architecture, development will proceed in the following phases:

1.  **Phase 1: Database Migration (The Ledger)**
    *   Create migrations for all registries (`instrument`, `maturity`, `direction`).
    *   Create migrations for `actors`, `financial_recordings`, and `ledger_entries`.
    *   Create instrument-specific tables (e.g., `promissory_notes`).
2.  **Phase 2: Core ActiveRecord Models**
    *   Implement `Actor`, `FinancialRecording`, `LedgerEntry`.
    *   Implement the `Contract` subclasses (`PromissoryNote`, `Bond`).
3.  **Phase 3: Concerns Integration**
    *   Write `Recordable` to enforce the double-entry accounting hook.
    *   Refactor `Exchangeable` and `Capitalizable` to operate on `FinancialRecordings` instead of standalone items.
4.  **Phase 4: Simulation Sandbox**
    *   Write a pure Rails `runner` script (`scripts/macro_circulation.rb`) that visually logs the origination, discounting, and capitalization of a single instrument through the ledger.
5.  **Phase 5: Data Ingestion (Reality Hook)**
    *   Develop the first Rake task (`lib/tasks/ingest_fred_rates.rake`) to pull the DPCREDIT rate and establish the system's baseline cost of capital.