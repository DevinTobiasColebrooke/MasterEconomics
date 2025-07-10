require 'rails_helper'
require_relative '../../../../../app/services/extinction_of_obligations_service/payment_in_money/release/debt_release_service'

RSpec.describe ExtinctionOfObligationsService::PaymentInMoney::Release::DebtReleaseService do
  let(:debtor) { ExtinctionOfObligationsService::Debtor::Debtor.new(100) }

  describe '.release_from_debt' do
    context 'when releasing a positive debt amount' do
      it 'increases the debtor property by the released debt amount' do
        initial_property = debtor.property
        debt_amount = 50

        described_class.release_from_debt(debtor, debt_amount)

        expect(debtor.property).to eq(initial_property + debt_amount)
      end

      it 'outputs the correct scenario information' do
        debt_amount = 75

        expect { described_class.release_from_debt(debtor, debt_amount) }.to output(
          /--- Scenario: Releasing from Debt ---/
        ).to_stdout
      end

      it 'outputs the before and after property values' do
        initial_property = debtor.property
        debt_amount = 25

        expect { described_class.release_from_debt(debtor, debt_amount) }.to output(
          /Debtor's property BEFORE release: \$#{initial_property}.*Debtor's property AFTER release: \$#{initial_property + debt_amount}/m
        ).to_stdout
      end

      it 'outputs the mathematical concept explanation' do
        expect { described_class.release_from_debt(debtor, 30) }.to output(
          /Now debt is -, and taking away or releasing, is also -: hence releasing a debt is - x -/
        ).to_stdout
      end

      it 'outputs the equivalence to gift explanation' do
        expect { described_class.release_from_debt(debtor, 40) }.to output(
          /releasing a debt is equivalent to making a gift of money/
        ).to_stdout
      end

      it 'outputs the mathematical equation' do
        expect { described_class.release_from_debt(debtor, 50) }.to output(
          /- x - = \+ \+/
        ).to_stdout
      end

      it 'outputs the effect description' do
        debt_amount = 60

        expect { described_class.release_from_debt(debtor, debt_amount) }.to output(
          /Effect: Debt of \$#{debt_amount} is released\. This is conceptually a \(- x -\) operation\./
        ).to_stdout
      end

      it 'outputs the property increase description' do
        debt_amount = 70

        expect { described_class.release_from_debt(debtor, debt_amount) }.to output(
          /Property \(net worth\) increased by \$#{debt_amount}\./
        ).to_stdout
      end

      it 'outputs the final statement about being richer' do
        debt_amount = 80

        expect { described_class.release_from_debt(debtor, debt_amount) }.to output(
          /Then the Debtor would be \$#{debt_amount} richer than before and his property would be 0\./
        ).to_stdout
      end
    end

    context 'when releasing a zero debt amount' do
      it 'does not change the debtor property' do
        initial_property = debtor.property

        described_class.release_from_debt(debtor, 0)

        expect(debtor.property).to eq(initial_property)
      end

      it 'still outputs the scenario information' do
        expect { described_class.release_from_debt(debtor, 0) }.to output(
          /--- Scenario: Releasing from Debt ---/
        ).to_stdout
      end
    end

    context 'when attempting to release a negative debt amount' do
      it 'outputs an error message' do
        expect { described_class.release_from_debt(debtor, -25) }.to output(
          "Error: Released debt amount cannot be negative.\n"
        ).to_stdout
      end

      it 'does not change the debtor property' do
        initial_property = debtor.property

        described_class.release_from_debt(debtor, -10)

        expect(debtor.property).to eq(initial_property)
      end
    end

    context 'with a debtor starting with zero property' do
      let(:zero_debtor) { ExtinctionOfObligationsService::Debtor::Debtor.new(0) }

      it 'correctly adds the released debt to zero property' do
        debt_amount = 100

        described_class.release_from_debt(zero_debtor, debt_amount)

        expect(zero_debtor.property).to eq(debt_amount)
      end
    end

    context 'with a debtor starting with positive property' do
      let(:positive_debtor) { ExtinctionOfObligationsService::Debtor::Debtor.new(0) }

      before { positive_debtor.property = 200 }

      it 'correctly adds the released debt to positive property' do
        debt_amount = 50

        described_class.release_from_debt(positive_debtor, debt_amount)

        expect(positive_debtor.property).to eq(250)
      end
    end

    context 'demonstrating the - x - = + concept' do
      it 'shows that releasing debt has the same effect as receiving a gift' do
        gift_debtor = ExtinctionOfObligationsService::Debtor::Debtor.new(100)
        release_debtor = ExtinctionOfObligationsService::Debtor::Debtor.new(100)
        amount = 75

        # Apply gift to one debtor
        ExtinctionOfObligationsService::PaymentInMoney::Gift::GiftService.receive_gift(gift_debtor, amount)

        # Apply debt release to another debtor
        described_class.release_from_debt(release_debtor, amount)

        # Both should have the same final property value
        expect(gift_debtor.property).to eq(release_debtor.property)
      end
    end
  end

  describe 'module structure' do
    it 'is properly nested in the ExtinctionOfObligationsService::PaymentInMoney::Release module' do
      expect(described_class.name).to eq('ExtinctionOfObligationsService::PaymentInMoney::Release::DebtReleaseService')
    end
  end
end
