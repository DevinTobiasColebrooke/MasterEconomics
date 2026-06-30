class Check < ApplicationRecord
  include Recordable
  include Exchangeable

  validates :amount_units, presence: true
  validates :check_number, presence: true
end