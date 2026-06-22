class Consumer
  attr_accessor :name, :cash_on_hand, :available_credit, :willingness_to_pay

  # @param name [String] Name of the consumer
  # @param cash_on_hand [Numeric] Liquid cash available
  # @param available_credit [Numeric] Ability to leverage future revenue for immediate purchasing power
  # @param abstract_desire [Numeric] The raw theoretical willingness to pay if money were no object
  def initialize(name, cash_on_hand, available_credit, abstract_desire)
    @name = name
    @cash_on_hand = cash_on_hand
    @available_credit = available_credit
    
    # In Economics, your effective desire (Willingness to Pay) 
    # cannot exceed your actual power to purchase.
    @willingness_to_pay = [abstract_desire, power_to_purchase].min
  end

  # Power to purchase is the sum of liquid cash and available credit (which is treated as capital)
  def power_to_purchase
    @cash_on_hand + @available_credit
  end

  # "Demand, therefore, in Economics must mean the desire and the power to purchase"
  # A consumer only demands the product if their effective willingness to pay meets or exceeds the price.
  #
  # @param price [Numeric] The market price
  def demands?(price)
    if @willingness_to_pay >= price
      true
    else
      # "When prices rise above a certain point... if they cannot give these prices they cease to buy..."
      false
    end
  end

  def display_status
    puts "Consumer: #{@name} | Power to Purchase: $#{power_to_purchase} (Cash: $#{@cash_on_hand}, Credit: $#{@available_credit}) | Effective Bid: $#{@willingness_to_pay}"
  end
end
