  module ExtinctionOfObligationsService
  module Debtor
    class Debtor
      # Allows external access to the 'property' (net worth) attribute.
      attr_accessor :property

      # Initializes a new Debtor instance.
      #
      # @param initial_debt [Numeric] The initial amount of debt the debtor has.
      #   This value should be positive, and it will be stored as a negative property.
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
  end
end
