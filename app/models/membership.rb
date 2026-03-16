# frozen_string_literal: true

class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :account

  enum :role, { owner: "owner", admin: "admin", collaborator: "collaborator" }

  scope :owner_or_admin, -> { where(role: [ "owner", "admin" ]) }

  validates :role, presence: true
  validates :user_id, uniqueness: { scope: :account_id }

  def removable_by?(user)
    !owner? && self.user != user
  end
end
