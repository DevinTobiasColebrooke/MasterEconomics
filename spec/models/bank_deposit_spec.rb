require "rails_helper"

RSpec.describe BankDeposit, type: :model do
  let!(:debtor) { Actor.create! }
  let!(:creditor) { Actor.create! }
  let!(:buyer) { Actor.create! }

  describe "validations" do
    it "is invalid without account_number" do
      deposit = BankDeposit.new(opened_on: Date.today)
      expect(deposit).not_to be_valid
      expect(deposit.errors[:account_number]).to include("can't be blank")
    end

    it "is invalid without opened_on" do
      deposit = BankDeposit.new(account_number: "DEP-123456")
      expect(deposit).not_to be_valid
      expect(deposit.errors[:opened_on]).to include("can't be blank")
    end
  end

  describe ".originate!" do
    it "creates the BankDeposit and balancing ledger entries" do
      deposit = BankDeposit.originate!(
        { account_number: "DEP-123456", opened_on: Date.today },
        value_units: 10000,
        liquidity_class_code: 10, # Demand Deposit (high liquidity)
        debtor: debtor,
        creditor: creditor
      )

      expect(deposit).to be_persisted
      expect(deposit.account_number).to eq("DEP-123456")
      expect(deposit.opened_on).to eq(Date.today)

      recording = deposit.financial_recording
      expect(recording).to be_present
      expect(recording.instrument_type.internal_code).to eq(40)

      # Check ledger entry directions and balances
      expect(debtor.duties_to_pay).to eq(10000)
      expect(debtor.property).to eq(0)
      expect(creditor.duties_to_pay).to eq(0)
      expect(creditor.property).to eq(10000)
    end
  end

  describe "Exchangeable behavior" do
    let!(:deposit) do
      BankDeposit.originate!(
        { account_number: "DEP-123456", opened_on: Date.today },
        value_units: 10000,
        liquidity_class_code: 10,
        debtor: debtor,
        creditor: creditor
      )
    end

    it "cannot be consumed unless produced first" do
      expect(deposit.consume!(buyer)).to be false
      expect(creditor.property).to eq(10000)
      expect(buyer.property).to eq(0)
    end

    it "transfers ownership of Right of Action from creditor to buyer upon consumption" do
      expect(deposit.produce!(10000)).to be true
      expect(deposit.consume!(buyer)).to be true

      # Bob (creditor) no longer owns the Right of Action
      expect(creditor.reload.property).to eq(0)
      # Buyer now owns the Right of Action
      expect(buyer.reload.property).to eq(10000)
      # Debtor's duty is unchanged
      expect(debtor.reload.duties_to_pay).to eq(10000)
    end
  end
end
