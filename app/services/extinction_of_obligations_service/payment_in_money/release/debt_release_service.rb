require_relative '../../../extinction_of_obligations_service/debtor/debtor_networth' # Ensure the Debtor class is available

module ExtinctionOfObligationsService
  module PaymentInMoney
    module Release
      class DebtReleaseService
        # Simulates the act of a debtor being released from a debt,
        # specifically detailing the "First Method" of extinguishing an obligation
        # through mutual consent.
        #
        # This method describes how an obligation, created by mutual consent,
        # can be cancelled and extinguished by the same mutual consent.
        # It illustrates the effect of this cancellation on both the debtor's
        # and the creditor's property.
        #
        # @param debtor [DebtorNetWorth] An instance of the DebtorNetWorth class
        #   representing the debtor whose property will be affected.
        # @param obligation_amount [Numeric] The amount of the obligation (debt)
        #   that is being cancelled. This should be a positive value.
        def self.release_from_debt(debtor, obligation_amount)
          if obligation_amount <= 0
            puts "Error: Obligation amount must be a positive value for cancellation."
            return
          end

          puts "\n--- Debt Release Service: Extinguishing Obligation ---"
          puts "Initial Debtor's Property (Net Worth): $#{debtor.property}"
          puts "Obligation Amount to be Cancelled: $#{obligation_amount}"

          puts "\n--- First Method: Extinguishing Obligation by Mutual Consent ---"
          puts "Concept: As an obligation was created by mutual consent, it may be cancelled by the same mutual consent."
          puts "To Create an Obligation is denoted by +{£#{obligation_amount}} or -{£#{obligation_amount}}."
          puts "So to Cancel, Extinguish, or Annihilate an Obligation is denoted by -{£#{obligation_amount}} or -{-£#{obligation_amount}}."

          # Effect on Creditor's Property:
          # The creditor's property effectively decreases by the obligation amount.
          # This is conceptually: - (+obligation_amount) = -obligation_amount
          creditor_loss = obligation_amount
          puts "\nObserving the effect of the Negative Sign on each of the parties:"
          puts "The Creditor's property becomes - (+ £#{obligation_amount})"
          puts "But - (+ £#{obligation_amount}) = - £#{creditor_loss}"
          puts "That is, the Creditor has lost $#{creditor_loss}."

          # Effect on Debtor's Property:
          # The debtor's property increases because the negative obligation is removed.
          # This is conceptually: - (-obligation_amount) = +obligation_amount
          puts "The Debtor's property becomes - (- £#{obligation_amount})"
          puts "But - (- £#{obligation_amount}) = + £#{obligation_amount}"

          # Update the debtor's property
          # Releasing a debt (a negative) is equivalent to adding a positive amount.
          debtor.property += obligation_amount

          puts "That is, the Debtor has gained $#{obligation_amount}."
          puts "Which shows that to Cancel or Release a Debt is exactly equivalent to making a Gift of Money."

          puts "Debtor's Property (Net Worth) AFTER obligation extinguished: $#{debtor.property}"
          puts "-------------------------------------------------------------------"
        end
      end
    end
  end
end
