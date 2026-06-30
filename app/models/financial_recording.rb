class FinancialRecording < ApplicationRecord
  belongs_to :instrument_type, class_name: 'InstrumentRegistry'
  belongs_to :liquidity_class, class_name: 'LiquidityClassRegistry'
  
  has_many :ledger_entries, foreign_key: :recording_id, dependent: :destroy
  
  validates :concrete_id, presence: true

  # Custom polymorphic-like resolver using pure integer instrument_type_id mapping.
  # This avoids any string-based database overhead and maintains maximum performance.
  def concrete
    @concrete ||= case instrument_type.internal_code
                  when 10 then PromissoryNote.find_by(id: concrete_id)
                  when 20 then Bond.find_by(id: concrete_id)
                  when 30 then Check.find_by(id: concrete_id)
                  when 40 then BankDeposit.find_by(id: concrete_id)
                  else nil
                  end
  end
end