class BankDeposit < ApplicationRecord
  include Recordable
  include Exchangeable

  validates :account_number, presence: true
  validates :opened_on, presence: true
end