require 'rails_helper'
require_relative '../../../../../app/services/extinction_of_obligations_service/payment_in_money/gift/gift_service'

RSpec.describe ExtinctionOfObligationsService::PaymentInMoney::Gift::GiftService do
  let(:debtor) { ExtinctionOfObligationsService::Debtor::Debtor.new(100) }

  describe '.receive_gift' do
    context 'when receiving a positive gift amount' do
      it 'increases the debtor property by the gift amount' do
        initial_property = debtor.property
        gift_amount = 50

        described_class.receive_gift(debtor, gift_amount)

        expect(debtor.property).to eq(initial_property + gift_amount)
      end

      it 'outputs the correct scenario information' do
        gift_amount = 75

        expect { described_class.receive_gift(debtor, gift_amount) }.to output(
          /--- Scenario: Receiving a Gift ---/
        ).to_stdout
      end

                  it 'outputs the before and after property values' do
        initial_property = debtor.property
        gift_amount = 25

        expect {
          described_class.receive_gift(debtor, gift_amount)
        }.to output(/Debtor's property BEFORE gift: \$#{initial_property}.*Debtor's property AFTER gift: \$#{initial_property + gift_amount}/m).to_stdout
      end

      it 'outputs the mathematical concept explanation' do
        expect { described_class.receive_gift(debtor, 30) }.to output(
          /The Gift of Money is \+ x \+, which equals \+./
        ).to_stdout
      end

      it 'outputs the effect description' do
        gift_amount = 40

        expect { described_class.receive_gift(debtor, gift_amount) }.to output(
          /Effect: Property \(net worth\) increased by \$#{gift_amount}\./
        ).to_stdout
      end

      it 'outputs the final statement about being richer' do
        gift_amount = 60

        expect { described_class.receive_gift(debtor, gift_amount) }.to output(
          /he would be \$#{gift_amount} richer than he was before/
        ).to_stdout
      end
    end

    context 'when receiving a zero gift amount' do
      it 'does not change the debtor property' do
        initial_property = debtor.property

        described_class.receive_gift(debtor, 0)

        expect(debtor.property).to eq(initial_property)
      end

      it 'still outputs the scenario information' do
        expect { described_class.receive_gift(debtor, 0) }.to output(
          /--- Scenario: Receiving a Gift ---/
        ).to_stdout
      end
    end

    context 'when attempting to receive a negative gift amount' do
      it 'outputs an error message' do
        expect { described_class.receive_gift(debtor, -25) }.to output(
          "Error: Gift amount cannot be negative.\n"
        ).to_stdout
      end

      it 'does not change the debtor property' do
        initial_property = debtor.property

        described_class.receive_gift(debtor, -10)

        expect(debtor.property).to eq(initial_property)
      end
    end

    context 'with a debtor starting with zero property' do
      let(:zero_debtor) { ExtinctionOfObligationsService::Debtor::Debtor.new(0) }

      it 'correctly adds the gift to zero property' do
        gift_amount = 100

        described_class.receive_gift(zero_debtor, gift_amount)

        expect(zero_debtor.property).to eq(gift_amount)
      end
    end

    context 'with a debtor starting with positive property' do
      let(:positive_debtor) { ExtinctionOfObligationsService::Debtor::Debtor.new(0) }

      before { positive_debtor.property = 200 }

      it 'correctly adds the gift to positive property' do
        gift_amount = 50

        described_class.receive_gift(positive_debtor, gift_amount)

        expect(positive_debtor.property).to eq(250)
      end
    end
  end

  describe 'module structure' do
    it 'is properly nested in the ExtinctionOfObligationsService::PaymentInMoney::Gift module' do
      expect(described_class.name).to eq('ExtinctionOfObligationsService::PaymentInMoney::Gift::GiftService')
    end
  end
end
