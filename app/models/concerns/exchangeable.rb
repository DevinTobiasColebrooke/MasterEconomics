module Exchangeable
  extend ActiveSupport::Concern

  # "Production" simply means offering the Right of Action for sale in the market.
  # It does not mean the physical creation of matter.
  def produce!(market_price)
    @current_market_price = market_price
    @status = :produced
    true
  end

  # "Consumption" simply means the act of purchasing.
  # Buying updates the party_id on the Right of Action ledger entry, transferring the wealth.
  def consume!(buyer)
    if @status != :produced
      return false
    end

    ActiveRecord::Base.transaction do
      recording = financial_recording
      if recording.nil?
        raise "Cannot find ledger recording for contract #{self.class.name} with ID #{self.id}"
      end

      right_of_action_direction = AccountDirectionRegistry.find_by!(internal_code: 1)
      ledger_entry = recording.ledger_entries.find_by!(direction: right_of_action_direction)

      # Update the owner (the creditor holding the Right of Action) to the buyer
      ledger_entry.update!(party: buyer)
      @status = :consumed
      true
    end
  end

  # Custom getter for the FinancialRecording hub
  def financial_recording
    @financial_recording ||= begin
      instrument_type = InstrumentRegistry.find_by!(internal_code: instrument_code)
      FinancialRecording.find_by(concrete_id: self.id, instrument_type_id: instrument_type.id)
    end
  end

  private

  def instrument_code
    case self.class.name
    when "PromissoryNote" then 10
    when "Bond"           then 20
    when "Check"          then 30
    when "BankDeposit"    then 40
    else raise "Unknown contract class: #{self.class.name}"
    end
  end
end