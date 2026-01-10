
This DDL treats the database as a pure repository of facts. It removes all logic, CHECK constraints (math-based validations), and calculations. It simply stores the data points as integers and dates, leaving the application to interpret them entirely.

```sql
-- ==========================================================
-- 1. REGISTRY LAYER (Integer Mapping Only)
-- ==========================================================

CREATE TABLE instrument_registry (
    id SMALLSERIAL PRIMARY KEY,
    internal_code SMALLINT UNIQUE NOT NULL 
);

CREATE TABLE maturity_registry (
    id SMALLSERIAL PRIMARY KEY,
    internal_code SMALLINT UNIQUE NOT NULL
);

CREATE TABLE account_direction_registry (
    id SMALLSERIAL PRIMARY KEY,
    internal_code SMALLINT UNIQUE NOT NULL
);

-- ==========================================================
-- 2. IDENTITY LAYER (Strings isolated here)
-- ==========================================================

CREATE TABLE actors (
    id SERIAL PRIMARY KEY
);

CREATE TABLE actor_profiles (
    id SERIAL PRIMARY KEY,
    actor_id INTEGER NOT NULL REFERENCES actors(id),
    display_name VARCHAR(255) NOT NULL
);

-- ==========================================================
-- 3. RECORDING LAYER (Metadata Hub)
-- ==========================================================

CREATE TABLE financial_recordings (
    id SERIAL PRIMARY KEY,
    instrument_type_id SMALLINT NOT NULL REFERENCES instrument_registry(id),
    concrete_id INTEGER NOT NULL, 
    creator_id INTEGER NOT NULL REFERENCES actors(id),
    created_at TIMESTAMP NOT NULL
);

-- ==========================================================
-- 4. CONCRETE INSTRUMENT TABLES (Raw Metrics)
-- ==========================================================

CREATE TABLE promissory_notes (
    id SERIAL PRIMARY KEY,
    face_value_units BIGINT NOT NULL,
    maturity_type_id SMALLINT NOT NULL REFERENCES maturity_registry(id),
    issuance_date DATE NOT NULL,
    due_date DATE 
);

CREATE TABLE bonds (
    id SERIAL PRIMARY KEY,
    par_value_units BIGINT NOT NULL,
    maturity_date DATE NOT NULL,
    cusip_hex_id VARBIT(72) 
);

CREATE TABLE checks (
    id SERIAL PRIMARY KEY,
    amount_units BIGINT NOT NULL,
    check_number INTEGER NOT NULL
);

-- ==========================================================
-- 5. LEDGER LAYER (The Raw Facts)
-- ==========================================================

CREATE TABLE ledger_entries (
    id SERIAL PRIMARY KEY,
    recording_id INTEGER NOT NULL REFERENCES financial_recordings(id),
    party_id INTEGER NOT NULL REFERENCES actors(id),
    direction_id SMALLINT NOT NULL REFERENCES account_direction_registry(id),
    value_units BIGINT NOT NULL
);

-- ==========================================================
-- 6. INITIAL SEEDING
-- ==========================================================

-- Instrument Types: 10=Note, 20=Bond, 30=Check
INSERT INTO instrument_registry (internal_code) VALUES (10), (20), (30);

-- Maturity Types: 1=On Demand, 2=Fixed Date
INSERT INTO maturity_registry (internal_code) VALUES (1), (2);

-- Account Directions: 1=Right of Action, 2=Duty to Pay
INSERT INTO account_direction_registry (internal_code) VALUES (1), (2);
```

### **Interest Terms**

```sql

```

### 

### **Daily Count conventions**

```sql
CREATE TABLE Day_Count_Conventions (
    Convention_ID SERIAL PRIMARY KEY,
    Label VARCHAR(50) NOT NULL,      -- 'Actual/Actual', 'Actual/365', '30/360'
    Days_In_Year_Logic VARCHAR(20),  -- 'Actual', 'Fixed_365', 'Fixed_360'
    Days_In_Month_Logic VARCHAR(20)  -- 'Actual', 'Fixed_30'
);
```

### **Rails Model Example:**

```py
# app/models/concerns/recordable.rb
module Recordable
  extend ActiveSupport::Concern

  included do
    has_one :financial_recording, as: :concrete
    # Mapping internal_codes to readable symbols
    enum instrument_type: { promissory_note: 10, bond: 20, check: 30 }, _prefix: true
  end
end

# app/models/ledger_entry.rb
class LedgerEntry < ApplicationRecord
  # No strings in DB, but readable in Ruby
  enum direction: { right_of_action: 1, duty_to_pay: 2 }, _suffix: true
  
  belongs_to :recording, class_name: 'FinancialRecording'
  belongs_to :party, class_name: 'Actor'
end

```
