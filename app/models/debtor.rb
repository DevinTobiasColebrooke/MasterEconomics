class Debtor
  # Include business logic capabilities via Concerns
  include GiftReceiver
  include ObligationReleasable

  # Allows external access to the 'property' (net worth) attribute.
  attr_accessor :property

  # Initializes a new Debtor instance.
  #
  # @param initial_debt [Numeric] The initial amount of debt the debtor has.
  def initialize(initial_debt = 0)
    # A positive initial_debt means the debtor's property starts as negative.
    # If initial_debt is 0, the property starts at 0.
    @property = -initial_debt
  end

  # Displays the current property (net worth) status of the debtor.
  def display_status
    puts "Current Property (Net Worth): $#{@property}"
  end
end
