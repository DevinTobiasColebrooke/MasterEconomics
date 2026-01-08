module ObligationReleasable
  extend ActiveSupport::Concern

  # Simulates the act of being released from a debt (The "First Method" of extinguishing an obligation).
  #
  # @param obligation_amount [Numeric] The amount of the obligation (debt) that is being cancelled.
  def release_from_debt(obligation_amount)
    if obligation_amount <= 0
      puts "Error: Obligation amount must be a positive value for cancellation."
      return
    end

    puts "\n--- Debt Release: Extinguishing Obligation ---"
    puts "Initial Debtor's Property (Net Worth): $#{self.property}"
    puts "Obligation Amount to be Cancelled: $#{obligation_amount}"

    puts "\n--- First Method: Extinguishing Obligation by Mutual Consent ---"
    puts "Concept: As an obligation was created by mutual consent, it may be cancelled by the same mutual consent."
    puts "To Create an Obligation is denoted by +{$#{obligation_amount}} or -{$#{obligation_amount}}."
    puts "So to Cancel, Extinguish, or Annihilate an Obligation is denoted by -{$#{obligation_amount}} or -{-$#{obligation_amount}}."

    # Effect on Creditor's Property:
    creditor_loss = obligation_amount
    puts "\nObserving the effect of the Negative Sign on each of the parties:"
    puts "The Creditor's property becomes - (+ $#{obligation_amount})"
    puts "But - (+ $#{obligation_amount}) = - $#{creditor_loss}"
    puts "That is, the Creditor has lost $#{creditor_loss}."

    # Effect on Debtor's Property:
    puts "The Debtor's property becomes - (- $#{obligation_amount})"
    puts "But - (- $#{obligation_amount}) = + $#{obligation_amount}"

    # Update the debtor's property
    # Releasing a debt (a negative) is equivalent to adding a positive amount.
    self.property += obligation_amount

    puts "That is, the Debtor has gained $#{obligation_amount}."
    puts "Which shows that to Cancel or Release a Debt is exactly equivalent to making a Gift of Money."

    puts "Debtor's Property (Net Worth) AFTER obligation extinguished: $#{self.property}"
    puts "-------------------------------------------------------------------"
  end
end
