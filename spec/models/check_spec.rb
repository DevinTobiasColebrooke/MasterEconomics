require "rails_helper"

RSpec.describe Check, type: :model do
  let!(:debtor) { Actor.create! }
  let!(:creditor) { Actor.create! }
  let!(:buyer) { Actor.create! }

  describe "validations" do
    it "is invalid without amount_units" do
      check = Check.new(check_number: 1001)
      expect(check).not_to be_valid
      expect(check.errors[:amount_units]).to include("can't be blank")
    end

    it "is invalid without check_number" do
      check = Check.new(amount_units: 300)
      expect(check).not_to be_valid
      expect(check.errors[:check_number]).to include("can't be blank")
    end
  end

  describe ".originate!" do
    it "creates the Check and balancing ledger entries" do
      check = Check.originate!(
        { amount_units: 300, check_number: 1001 },
        value_units: 300,
        liquidity_class_code: 10, # Demand Deposit (high liquidity)
        debtor: debtor,
        creditor: creditor
      )

      expect(check).to be_persisted
      expect(check.amount_units).to eq(300)
      expect(check.check_number).to eq(1001)

      recording = check.financial_recording
      expect(recording).to be_present
      expect(recording.instrument_type.internal_code).to eq(30)

      # Check ledger entry directions and balances
      expect(debtor.duties_to_pay).to eq(300)
      expect(debtor.property).to eq(0)
      expect(creditor.duties_to_pay).to eq(0)
      expect(creditor.property).to eq(300)
    end
  end

  describe "Exchangeable behavior" do
    let!(:check) do
      Check.originate!(
        { amount_units: 300, check_number: 1001 },
        value_units: 300,
        liquidity_class_code: 10,
        debtor: debtor,
        creditor: creditor
      )
    end

    it "cannot be consumed unless produced first" do
      expect(check.consume!(buyer)).to be false
      expect(creditor.property).to eq(300)
      expect(buyer.property).to eq(0)
    end

    it "transfers ownership of Right of Action from creditor to buyer upon consumption" do
      expect(check.produce!(300)).to be true
      expect(check.consume!(buyer)).to be true

      # Bob (creditor) no longer owns the Right of Action
      expect(creditor.reload.property).to eq(0)
      # Buyer now owns the Right of Action
      expect(buyer.reload.property).to eq(300)
      # Debtor's duty is unchanged
      expect(debtor.reload.duties_to_pay).to eq(300)
    end
  end
end
