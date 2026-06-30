class Actor < ApplicationRecord
  has_one :actor_profile, dependent: :destroy
  has_many :ledger_entries, foreign_key: :party_id

  # Sum of all ledger entries representing a Right of Action (internal code 1)
  # This dynamically calculates the Actor's total Property (potential purchasing power).
  def property
    right_of_action = AccountDirectionRegistry.find_by!(internal_code: 1)
    ledger_entries.where(direction: right_of_action).sum(:value_units)
  end

  # Sum of all ledger entries representing a Duty to Pay (internal code 2)
  # Tracked completely separately, never netted against Property.
  def duties_to_pay
    duty_to_pay = AccountDirectionRegistry.find_by!(internal_code: 2)
    ledger_entries.where(direction: duty_to_pay).sum(:value_units)
  end

  # Displays the actor's current financial posture, clearly separating potential from obligation.
  def display_status
    profile_name = actor_profile&.display_name || "Actor ##{id}"
    puts "\n=============================================="
    puts "Actor Profile: #{profile_name}"
    puts "----------------------------------------------"
    puts "Potential Purchasing Power (Property): #{property} units"
    puts "Total Obligations (Duties to Pay):     #{duties_to_pay} units"
    puts "=============================================="
  end
end