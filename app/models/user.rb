class User < ActiveRecord::Base
  devise :database_authenticatable
  has_and_belongs_to_many :groups
  
  def admin?
    self.groups.where(name: 'administrator').exists?
  end
  
  def super?
    self.groups.where(name: 'supervisor').exists? || self.admin?
  end
  
  def clerk?
    self.groups.where(name: 'clerk').exists? || self.super? || self.admin?
  end
end
