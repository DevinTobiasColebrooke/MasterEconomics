require_relative '../../../debtor/debtor_networth' # Ensure the Debtor class is available

module ExtinctionOfObligationsService
  module PaymentInMoney
    module Release
      class DebtReleaseService
        # Simulates the act of a debtor being released from a debt.
        # This is the core demonstration of the (- x - = +) concept.
        #
        # @param debtor [Debtor] An instance of the Debtor class whose property will be affected.
        # @param amount [Numeric] The amount of debt from which the debtor is released.
        def self.release_from_debt(debtor, amount)
          if amount < 0
            puts "Error: Released debt amount cannot be negative."
            return
          end

          puts "\n--- Scenario: Releasing from Debt ---"
          puts "Action: The creditor simply releases the debtor from a debt of $#{amount}."
          puts "Concept: 'Now debt is -, and taking away or releasing, is also -: hence releasing a debt is - x -; hence releasing a debt is equivalent to making a gift of money. that is, - x - = + +.'"
          puts "Debtor's property BEFORE release: $#{debtor.property}"

          # Releasing a debt means the negative impact of that debt on the net worth is removed.
          # This is equivalent to adding a positive amount to the net worth.
          # Here, we are effectively applying a "negative" operation (releasing)
          # to a "negative" state (debt), resulting in a "positive" change.
          debtor.property += amount

          puts "Effect: Debt of $#{amount} is released. This is conceptually a (- x -) operation."
          puts "Property (net worth) increased by $#{amount}."
          puts "Debtor's property AFTER release: $#{debtor.property}."
          puts "As stated: 'Then the Debtor would be $#{amount} richer than before and his property would be 0.'"
          puts "----------------------------------------------------"
        end
      end
    end
  end
end
