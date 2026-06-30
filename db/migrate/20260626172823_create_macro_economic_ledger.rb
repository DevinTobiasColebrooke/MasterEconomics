class CreateMacroEconomicLedger < ActiveRecord::Migration[8.0]
  def change
    # ==========================================================
    # 1. REGISTRY LAYER
    # ==========================================================
    create_table :instrument_registry do |t|
      t.integer :internal_code, null: false, index: { unique: true }
    end

    create_table :liquidity_class_registry do |t|
      t.integer :internal_code, null: false, index: { unique: true }
    end

    create_table :account_direction_registry do |t|
      t.integer :internal_code, null: false, index: { unique: true }
    end

    # ==========================================================
    # 2. IDENTITY LAYER
    # ==========================================================
    create_table :actors do |t|
      # Base identity table
    end

    create_table :actor_profiles do |t|
      t.references :actor, null: false, foreign_key: true
      t.string :display_name, null: false
    end

    # ==========================================================
    # 3. RECORDING LAYER (Metadata Hub)
    # ==========================================================
    create_table :financial_recordings do |t|
      t.references :instrument_type, null: false, foreign_key: { to_table: :instrument_registry }
      t.references :liquidity_class, null: false, foreign_key: { to_table: :liquidity_class_registry }
      t.integer :concrete_id, null: false
      t.datetime :created_at, null: false
    end

    # ==========================================================
    # 4. CONCRETE INSTRUMENT TABLES
    # ==========================================================
    create_table :promissory_notes do |t|
      t.bigint :face_value_units, null: false
      t.date :issuance_date, null: false
      t.date :due_date
    end

    create_table :bonds do |t|
      t.bigint :par_value_units, null: false
      t.date :maturity_date, null: false
      t.string :cusip_hex_id, limit: 72
    end

    create_table :checks do |t|
      t.bigint :amount_units, null: false
      t.integer :check_number, null: false
    end

    # ==========================================================
    # 5. LEDGER LAYER
    # ==========================================================
    create_table :ledger_entries do |t|
      t.references :recording, null: false, foreign_key: { to_table: :financial_recordings }
      t.references :party, null: false, foreign_key: { to_table: :actors }
      t.references :direction, null: false, foreign_key: { to_table: :account_direction_registry }
      t.bigint :value_units, null: false
    end

    # ==========================================================
    # 6. CONVENTIONS
    # ==========================================================
    create_table :day_count_conventions do |t|
      t.string :label, null: false, limit: 50
      t.string :days_in_year_logic, limit: 20
      t.string :days_in_month_logic, limit: 20
    end

    reversible do |dir|
      dir.up do
        # Instrument Types: 10=Note, 20=Bond, 30=Check
        execute "INSERT INTO instrument_registry (internal_code) VALUES (10), (20), (30)"
        
        # Liquidity Classes: 10=Demand Deposit, 20=Revolving, 30=Fixed Term
        execute "INSERT INTO liquidity_class_registry (internal_code) VALUES (10), (20), (30)"
        
        # Account Directions: 1=Right of Action, 2=Duty to Pay
        execute "INSERT INTO account_direction_registry (internal_code) VALUES (1), (2)"
      end
    end
  end
end