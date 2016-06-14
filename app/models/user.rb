class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable, :validatable

  scope :with_email, -> (email) { where email: email }
  scope :with_name, -> (name) { where name: name }

  def paginate(*args) super args; end
  def order(arg) super arg; end

  validates :name, presence: true, length: { minimum: 3, maximum: 512 }

  before_validation { self.email = email.downcase unless email.nil? }
  before_validation { self.name = email unless name || email.nil? }
end
