class Bond < ApplicationRecord
  include Recordable
  include Exchangeable

  validates :par_value_units, presence: true
  validates :maturity_date, presence: true
end