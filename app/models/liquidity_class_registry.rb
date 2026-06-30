class LiquidityClassRegistry < ApplicationRecord
  self.table_name = "liquidity_class_registry"
  
  has_many :financial_recordings, foreign_key: :liquidity_class_id
end
