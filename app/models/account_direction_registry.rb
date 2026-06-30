class AccountDirectionRegistry < ApplicationRecord
  self.table_name = "account_direction_registry"
  
  has_many :ledger_entries, foreign_key: :direction_id
end
