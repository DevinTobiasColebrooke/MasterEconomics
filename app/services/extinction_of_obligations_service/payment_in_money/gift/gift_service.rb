require_relative '../../../extinction_of_obligations_service/debtor/debtor_networth' # Ensure the Debtor class is available

module ExtinctionOfObligationsService
  module PaymentInMoney
    module Gift
      class GiftService
        # Simulates the act of a debtor receiving a financial gift.
        #
        # @param debtor [Debtor] An instance of the Debtor class whose property will be affected.
        # @param amount [Numeric] The positive amount of money received as a gift.
        def self.receive_gift(debtor, amount)
          if amount < 0
            puts "Error: Gift amount cannot be negative."
            return
          end

          puts "\n--- Scenario: Receiving a Gift ---"
          puts "Action: A person makes a present of $#{amount} to the debtor."
          puts "Concept: 'The Gift of Money is + x +, which equals +.'"
          puts "Debtor's property BEFORE gift: $#{debtor.property}"

          # A gift is a direct positive addition to property.
          # This represents a positive operation (+amount) on the current property.
          debtor.property += amount

          puts "Effect: Property (net worth) increased by $#{amount}."
          puts "Debtor's property AFTER gift: $#{debtor.property}."
          puts "As stated: '...he would be $#{amount} richer than he was before: though his property would then be 0.'"
          puts "----------------------------------------------------"
        end
      end
    end
  end
end
