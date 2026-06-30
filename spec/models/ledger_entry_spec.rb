require "rails_helper"

RSpec.describe LedgerEntry, type: :model do
  let!(:actor) { Actor.create! }
  let!(:recording) do
    instrument_note = InstrumentRegistry.find_by!(internal_code: 10)
    liquidity_term = LiquidityClassRegistry.find_by!(internal_code: 30)
    FinancialRecording.create!(
      instrument_type: instrument_note,
      liquidity_class: liquidity_term,
      concrete_id: 1,
      created_at: Time.current
    )
  end
  let!(:direction) { AccountDirectionRegistry.find_by!(internal_code: 1) }

  describe "validations" do
    it "is valid with all attributes" do
      entry = LedgerEntry.new(
        recording: recording,
        party: actor,
        direction: direction,
        value_units: 100
      )
      expect(entry).to be_valid
    end

    it "requires value_units" do
      entry = LedgerEntry.new(
        recording: recording,
        party: actor,
        direction: direction
      )
      expect(entry).not_to be_valid
      expect(entry.errors[:value_units]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to recording, party, and direction" do
      entry = LedgerEntry.create!(
        recording: recording,
        party: actor,
        direction: direction,
        value_units: 100
      )
      expect(entry.recording).to eq(recording)
      expect(entry.party).to eq(actor)
      expect(entry.direction).to eq(direction)
    end
  end
end
