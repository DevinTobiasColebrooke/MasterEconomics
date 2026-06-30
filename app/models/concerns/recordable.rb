module Recordable
  extend ActiveSupport::Concern

  class_methods do
    # Originate a new contract and record it in the ledger using strict double-entry logic.
    # This guarantees that the contract creation and its ledger entries are fully atomic.
    def originate!(attributes, value_units:, liquidity_class_code:, debtor:, creditor:)
      ActiveRecord::Base.transaction do
        # 1. Map class name to registry code
        instrument_code = case name
                          when "PromissoryNote" then 10
                          when "Bond"           then 20
                          when "Check"          then 30
                          when "BankDeposit"    then 40
                          else raise "Unknown contract class: #{name}"
                          end

        instrument_type = InstrumentRegistry.find_by!(internal_code: instrument_code)
        liquidity_class = LiquidityClassRegistry.find_by!(internal_code: liquidity_class_code)
        right_of_action = AccountDirectionRegistry.find_by!(internal_code: 1)
        duty_to_pay     = AccountDirectionRegistry.find_by!(internal_code: 2)

        # 2. Create the concrete contract
        concrete_record = create!(attributes)

        # 3. Create the FinancialRecording hub representing mutual consent
        recording = FinancialRecording.create!(
          instrument_type: instrument_type,
          liquidity_class: liquidity_class,
          concrete_id: concrete_record.id,
          created_at: Time.current
        )

        # 4. Create the balancing LedgerEntries
        # Creditor gets the Right of Action (+)
        LedgerEntry.create!(
          recording: recording,
          party: creditor,
          direction: right_of_action,
          value_units: value_units
        )

        # Debtor gets the Duty to Pay (-)
        LedgerEntry.create!(
          recording: recording,
          party: debtor,
          direction: duty_to_pay,
          value_units: value_units
        )

        concrete_record
      end
    end
  end
end