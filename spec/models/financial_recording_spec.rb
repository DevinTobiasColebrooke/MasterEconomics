require "rails_helper"

RSpec.describe FinancialRecording, type: :model do
  let!(:debtor) { Actor.create! }
  let!(:creditor) { Actor.create! }

  let(:instrument_note) { InstrumentRegistry.find_by!(internal_code: 10) }
  let(:liquidity_term) { LiquidityClassRegistry.find_by!(internal_code: 30) }

  describe "validations" do
    it "requires concrete_id" do
      recording = FinancialRecording.new(
        instrument_type: instrument_note,
        liquidity_class: liquidity_term
      )
      expect(recording).not_to be_valid
      expect(recording.errors[:concrete_id]).to include("can't be blank")
    end
  end

  describe "#concrete resolver" do
    it "resolves to a PromissoryNote when internal_code is 10" do
      note = PromissoryNote.originate!(
        { face_value_units: 1000, issuance_date: Date.today },
        value_units: 1000,
        liquidity_class_code: 30,
        debtor: debtor,
        creditor: creditor
      )

      recording = FinancialRecording.find_by!(concrete_id: note.id, instrument_type: instrument_note)
      expect(recording.concrete).to eq(note)
    end

    it "resolves to a Bond when internal_code is 20" do
      bond = Bond.originate!(
        { par_value_units: 5000, maturity_date: Date.today + 1.year },
        value_units: 5000,
        liquidity_class_code: 30,
        debtor: debtor,
        creditor: creditor
      )

      instrument_bond = InstrumentRegistry.find_by!(internal_code: 20)
      recording = FinancialRecording.find_by!(concrete_id: bond.id, instrument_type: instrument_bond)
      expect(recording.concrete).to eq(bond)
    end

    it "resolves to a Check when internal_code is 30" do
      check = Check.originate!(
        { amount_units: 150, check_number: 12345 },
        value_units: 150,
        liquidity_class_code: 10, # Demand Deposit (liquidity)
        debtor: debtor,
        creditor: creditor
      )

      instrument_check = InstrumentRegistry.find_by!(internal_code: 30)
      recording = FinancialRecording.find_by!(concrete_id: check.id, instrument_type: instrument_check)
      expect(recording.concrete).to eq(check)
    end

    it "resolves to a BankDeposit when internal_code is 40" do
      deposit = BankDeposit.originate!(
        { account_number: 987654321, opened_on: Date.today },
        value_units: 2000,
        liquidity_class_code: 10,
        debtor: debtor,
        creditor: creditor
      )

      instrument_deposit = InstrumentRegistry.find_by!(internal_code: 40)
      recording = FinancialRecording.find_by!(concrete_id: deposit.id, instrument_type: instrument_deposit)
      expect(recording.concrete).to eq(deposit)
    end
  end
end
