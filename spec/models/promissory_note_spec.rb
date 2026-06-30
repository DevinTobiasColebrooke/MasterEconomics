require "rails_helper"

RSpec.describe PromissoryNote, type: :model do
  let!(:debtor) { Actor.create! }
  let!(:creditor) { Actor.create! }
  let!(:buyer) { Actor.create! }

  describe "validations" do
    it "is invalid without face_value_units" do
      note = PromissoryNote.new(issuance_date: Date.today)
      expect(note).not_to be_valid
      expect(note.errors[:face_value_units]).to include("can't be blank")
    end

    it "is invalid without issuance_date" do
      note = PromissoryNote.new(face_value_units: 1000)
      expect(note).not_to be_valid
      expect(note.errors[:issuance_date]).to include("can't be blank")
    end
  end

  describe ".originate!" do
    it "creates the PromissoryNote and balancing ledger entries" do
      note = PromissoryNote.originate!(
        { face_value_units: 1000, issuance_date: Date.today, due_date: Date.today + 90.days },
        value_units: 1000,
        liquidity_class_code: 30, # Fixed Term
        debtor: debtor,
        creditor: creditor
      )

      expect(note).to be_persisted
      expect(note.face_value_units).to eq(1000)
      expect(note.due_date).to eq(Date.today + 90.days)

      recording = note.financial_recording
      expect(recording).to be_present
      expect(recording.instrument_type.internal_code).to eq(10)

      # Check ledger entry directions and balances
      expect(debtor.duties_to_pay).to eq(1000)
      expect(debtor.property).to eq(0)
      expect(creditor.duties_to_pay).to eq(0)
      expect(creditor.property).to eq(1000)
    end
  end

  describe "Exchangeable behavior" do
    let!(:note) do
      PromissoryNote.originate!(
        { face_value_units: 1000, issuance_date: Date.today },
        value_units: 1000,
        liquidity_class_code: 30,
        debtor: debtor,
        creditor: creditor
      )
    end

    it "cannot be consumed unless produced first" do
      expect(note.consume!(buyer)).to be false
      expect(creditor.property).to eq(1000)
      expect(buyer.property).to eq(0)
    end

    it "transfers ownership of Right of Action from creditor to buyer upon consumption" do
      expect(note.produce!(950)).to be true
      expect(note.consume!(buyer)).to be true

      # Bob (creditor) no longer owns the Right of Action (Property is now 0)
      expect(creditor.reload.property).to eq(0)
      # Buyer now owns the Right of Action (Property is 1000)
      expect(buyer.reload.property).to eq(1000)
      # Debtor's duty is unchanged
      expect(debtor.reload.duties_to_pay).to eq(1000)
    end
  end
end
