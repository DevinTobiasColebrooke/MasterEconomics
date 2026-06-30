class LedgerEntry < ApplicationRecord
  belongs_to :recording, class_name: 'FinancialRecording'
  belongs_to :party, class_name: 'Actor'
  belongs_to :direction, class_name: 'AccountDirectionRegistry'
  
  validates :value_units, presence: true
end
