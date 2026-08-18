class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  validates :name, presence: true

  # The only place the app asks whether someone may administer it. Swapping the
  # boolean for roles or RBAC should not require touching any controller.
  def can_administer?
    admin?
  end
end
