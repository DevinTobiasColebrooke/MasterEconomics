require "rails_helper"

RSpec.describe Actor, type: :model do
  let!(:debtor) { Actor.create! }
  let!(:creditor) { Actor.create! }

  let!(:debtor_profile) { ActorProfile.create!(actor: debtor, display_name: "Alice Debtor") }
  let!(:creditor_profile) { ActorProfile.create!(actor: creditor, display_name: "Bob Creditor") }

  describe "#property and #duties_to_pay" do
    it "starts with zero property and zero duties to pay" do
      expect(debtor.property).to eq(0)
      expect(debtor.duties_to_pay).to eq(0)
      expect(creditor.property).to eq(0)
      expect(creditor.duties_to_pay).to eq(0)
    end

    it "records double-entry transaction values correctly on origination" do
      # Alice (debtor) originates a Promissory Note to Bob (creditor) for 500 units
      note = PromissoryNote.originate!(
        { face_value_units: 500, issuance_date: Date.today },
        value_units: 500,
        liquidity_class_code: 30, # Fixed Term
        debtor: debtor,
        creditor: creditor
      )

      expect(note).to be_persisted
      expect(FinancialRecording.count).to eq(1)
      expect(LedgerEntry.count).to eq(2)

      # Alice now has a Duty to Pay 500
      expect(debtor.property).to eq(0)
      expect(debtor.duties_to_pay).to eq(500)

      # Bob now has a Right of Action (Property) of 500
      expect(creditor.property).to eq(500)
      expect(creditor.duties_to_pay).to eq(0)
    end
  end

  describe "#display_status" do
    it "outputs the correct financial posture format to stdout" do
      expect { debtor.display_status }.to output(
        /Alice Debtor.*Potential Purchasing Power \(Property\): 0 units.*Total Obligations \(Duties to Pay\):     0 units/m
      ).to_stdout
    end
  end
end