class AddBankDepositsToLedger < ActiveRecord::Migration[8.0]
  def change
    create_table :bank_deposits do |t|
      t.string :account_number, null: false
      t.date :opened_on, null: false
    end

    reversible do |dir|
      dir.up do
        # 40 = Bank Deposit
        execute "INSERT INTO instrument_registry (internal_code) VALUES (40)"
      end
    end
  end
end