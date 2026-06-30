class ActorProfile < ApplicationRecord
  belongs_to :actor
  
  validates :display_name, presence: true
end
