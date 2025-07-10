require 'rails_helper'
require_relative '../../../../app/services/extinction_of_obligations_service/debtor/debtor_networth'

RSpec.describe ExtinctionOfObligationsService::Debtor::Debtor do
  describe '#initialize' do
    context 'when initialized with no arguments' do
      it 'creates a debtor with zero property' do
        debtor = described_class.new
        expect(debtor.property).to eq(0)
      end
    end

    context 'when initialized with positive debt' do
      it 'creates a debtor with negative property equal to the debt' do
        debtor = described_class.new(100)
        expect(debtor.property).to eq(-100)
      end
    end

    context 'when initialized with zero debt' do
      it 'creates a debtor with zero property' do
        debtor = described_class.new(0)
        expect(debtor.property).to eq(0)
      end
    end
  end

  describe '#property' do
    it 'allows reading and writing the property attribute' do
      debtor = described_class.new(50)
      expect(debtor.property).to eq(-50)

      debtor.property = 100
      expect(debtor.property).to eq(100)
    end
  end

  describe '#display_status' do
    it 'outputs the current property status' do
      debtor = described_class.new(75)

      # Capture the output
      expect { debtor.display_status }.to output("Current Property (Net Worth): $#{debtor.property}\n").to_stdout
    end

    it 'displays positive property correctly' do
      debtor = described_class.new
      debtor.property = 200

      expect { debtor.display_status }.to output("Current Property (Net Worth): $200\n").to_stdout
    end

    it 'displays negative property correctly' do
      debtor = described_class.new(150)

      expect { debtor.display_status }.to output("Current Property (Net Worth): $-150\n").to_stdout
    end
  end

  describe 'module structure' do
    it 'is properly nested in the ExtinctionOfObligationsService::Debtor module' do
      expect(described_class.name).to eq('ExtinctionOfObligationsService::Debtor::Debtor')
    end
  end
end
