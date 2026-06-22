module Exchangeable
  extend ActiveSupport::Concern

  # In our economic model, "Production" simply means offering an item for sale in the market.
  # It does not mean the physical creation of matter.
  def produce!(market_price)
    puts "\n--- Production Phase ---"
    puts "Action: #{self.class.name} is produced (offered for sale) at $#{market_price}."
    
    # In a full ActiveRecord implementation, this might update a state machine to 'in_market'
    @current_market_price = market_price
    @status = :produced 
  end

  # "Consumption" simply means the act of purchasing. It does not imply the physical
  # destruction of the asset (unless the asset is specifically food/fuel).
  #
  # @param buyer [Object] The entity purchasing the asset
  def consume!(buyer)
    puts "\n--- Consumption Phase ---"
    
    if @status != :produced
      puts "Error: Cannot consume an item that is not produced (offered for sale) in the market."
      return false
    end

    price = @current_market_price || 0

    if buyer.respond_to?(:demands?) && buyer.demands?(price)
      puts "Action: #{buyer.name} consumes (purchases) the #{self.class.name} for $#{price}."
      @status = :consumed
      true
    else
      puts "Action: #{buyer.name} lacks the effective demand (willingness/power to purchase) for the #{self.class.name} at $#{price}."
      false
    end
  end
end
