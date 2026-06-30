class PromissoryNote < ApplicationRecord
  include Recordable
  include Exchangeable

  validates :face_value_units, presence: true
  validates :issuance_date, presence: true
end