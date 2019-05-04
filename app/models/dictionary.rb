class Dictionary < ActiveRecord::Base

    validates :name, :code, presence: true
    validates :code, numericality: { only_integer: true}
end
