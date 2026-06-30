class InstrumentRegistry < ApplicationRecord
  self.table_name = "instrument_registry"
  
  has_many :financial_recordings, foreign_key: :instrument_type_id
end
