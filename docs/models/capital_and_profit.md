# Capital, Profit, and Economic Velocity

Based on the classical economic principles outlined in our core texts, this document establishes how we model Capital, Profit, Interest, and the mechanics of Exchange in our system.

## 1. Production and Consumption

In our system, we discard the physical notions of creation and destruction. We define these terms purely by their commercial action:

*   **Production:** The act of bringing a quantity into the market and offering it for sale.
*   **Consumption:** The act of purchasing that quantity.

An economic cycle is simply an **Exchange**. The system does not need to simulate the physical degradation of assets (unless required for depreciation accounting); it only needs to simulate the transfer of ownership and the settling of the ledger.

## 2. Capital and Intent

**Capital** is any Economic Quantity used for the purpose of profit. Credit is explicitly recognized as Capital, as it functions identically to cash in creating purchasing power.

Assets are not inherently "fixed" or "floating" based on their physical nature. Their classification depends entirely on the owner's intent:

*   **Floating (Circulating) Capital:** The owner intends to sell the asset outright in one operation to recover costs plus profit.
*   **Fixed Capital:** The owner intends to retain possession and let the asset out for hire/rent, recovering the cost and profit via periodic installments over time.

## 3. The Mathematics of Profit and Interest

A critical oversight in many economic models is the omission of **Time** when calculating the rate of profit. A 5% absolute profit is meaningless without knowing the duration of the transaction.

### Variables
*   `P_revenue`: Total revenue from the sale.
*   `C_cost`: Total capital employed (cost of goods + overhead).
*   `T_days`: The turnaround time (days between purchase and sale).

### Formulas

**1. Absolute Profit:**
`Absolute Profit = P_revenue - C_cost`

**2. Absolute Profit Margin:**
`Absolute Margin = (P_revenue - C_cost) / C_cost`

**3. Annualized Rate of Profit:**
This represents the true velocity of capital. A Parisian provision dealer making 3 francs profit on a 5 franc daily loan has a low absolute capital requirement but a massive annualized rate.

`Annualized Rate of Profit = Absolute Margin * (365 / T_days)`

**4. Comparing Interest to Profit:**
Interest on loans is always calculated on an annualized basis (Rate per Annum). To determine if a trade is viable on borrowed capital, the *Annualized Rate of Profit* must exceed the *Annualized Rate of Interest*.

If a trader borrows $100 at 20% annual interest, but uses that $100 to make a 5% profit every single week (turnaround time = 7 days), their annualized rate of profit is roughly 260%. This easily covers the 20% annualized interest, demonstrating how high-interest micro-loans can be economically viable.

## 4. Modeling Implications

To accurately reflect these mechanics in our Ruby models:

1.  **Transactions must be timestamped:** We need the exact duration an asset was held to calculate its true rate of profit.
2.  **Purchasing Power:** A buyer's ability to consume (demand) is defined as `Cash + Available Credit`.
3.  **Asset Classification:** Entities representing sellable goods must have an attribute denoting whether they are currently being treated as floating or fixed capital.
