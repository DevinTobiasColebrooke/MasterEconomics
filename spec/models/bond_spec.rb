require "rails_helper"

RSpec.describe Bond, type: :model do
  let!(:debtor) { Actor.create! }
  let!(:creditor) { Actor.create! }
  let!(:buyer) { Actor.create! }

  describe "validations" do
    it "is invalid without par_value_units" do
      bond = Bond.new(maturity_date: Date.today + 1.year)
      expect(bond).not_to be_valid
      expect(bond.errors[:par_value_units]).to include("can't be blank")
    end

    it "is invalid without maturity_date" do
      bond = Bond.new(par_value_units: 5000)
      expect(bond).not_to be_valid
      expect(bond.errors[:maturity_date]).to include("can't be blank")
    end
  end

  describe ".originate!" do
    it "creates the Bond and balancing ledger entries" do
      bond = Bond.originate!(
        { par_value_units: 5000, maturity_date: Date.today + 1.year, cusip_hex_id: "US1234567890" },
        value_units: 5000,
        liquidity_class_code: 30, # Fixed Term
        debtor: debtor,
        creditor: creditor
      )

      expect(bond).to be_persisted
      expect(bond.par_value_units).to eq(5000)
      expect(bond.cusip_hex_id).to eq("US1234567890")

      recording = bond.financial_recording
      expect(recording).to be_present
      expect(recording.instrument_type.internal_code).to eq(20)

      # Check ledger entry directions and balances
      expect(debtor.duties_to_pay).to eq(5000)
      expect(debtor.property).to eq(0)
      expect(creditor.duties_to_pay).to eq(0)
      expect(creditor.property).to eq(5000)
    end
  end

  describe "Exchangeable behavior" do
    let!(:bond) do
      Bond.originate!(
        { par_value_units: 5000, maturity_date: Date.today + 1.year },
        value_units: 5000,
        liquidity_class_code: 30,
        debtor: debtor,
        creditor: creditor
      )
    end

    it "cannot be consumed unless produced first" do
      expect(bond.consume!(buyer)).to be false
      expect(creditor.property).to eq(5000)
      expect(buyer.property).to eq(0)
    end

    it "transfers ownership of Right of Action from creditor to buyer upon consumption" do
      expect(bond.produce!(4900)).to be true
      expect(bond.consume!(buyer)).to be true

      # Bob (creditor) no longer owns the Right of Action
      expect(creditor.reload.property).to eq(0)
      # Buyer now owns the Right of Action
      expect(buyer.reload.property).to eq(5000)
      # Debtor's duty is unchanged
      expect(debtor.reload.duties_to_pay).to eq(5000)
    end
  end
end
