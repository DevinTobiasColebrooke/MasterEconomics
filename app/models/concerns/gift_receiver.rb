module GiftReceiver
  extend ActiveSupport::Concern

  # Simulates the act of receiving a financial gift.
  #
  # @param amount [Numeric] The positive amount of money received as a gift.
  def receive_gift(amount)
    if amount < 0
      puts "Error: Gift amount cannot be negative."
      return
    end

    puts "\n--- Scenario: Receiving a Gift ---"
    puts "Action: A person makes a present of $#{amount} to the debtor."
    puts "Concept: 'The Gift of Money is + x +, which equals +.'"
    puts "Debtor's property BEFORE gift: $#{self.property}"

    # A gift is a direct positive addition to property.
    # This represents a positive operation (+amount) on the current property.
    self.property += amount

    puts "Effect: Property (net worth) increased by $#{amount}."
    puts "Debtor's property AFTER gift: $#{self.property}."
    puts "As stated: '...he would be $#{amount} richer than he was before: though his property would then be 0.'"
    puts "----------------------------------------------------"
  end
end
