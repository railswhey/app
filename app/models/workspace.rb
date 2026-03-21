# frozen_string_literal: true

class Workspace < ApplicationRecord
  has_many :members, dependent: :destroy
  has_many :lists, dependent: :destroy
  has_many :tasks, through: :lists
  has_one  :inbox, -> { inbox }, inverse_of: :workspace, dependent: nil, class_name: "List"

  has_many :outgoing_transfers, foreign_key: :from_workspace_id, dependent: :destroy, class_name: "List::Transfer"
  has_many :incoming_transfers, foreign_key: :to_workspace_id,   dependent: :destroy, class_name: "List::Transfer"

  validates :uuid, presence: true, format: { with: UUID::REGEXP }, uniqueness: true

  def search(query)
    Search.new(self).by(query)
  end
end
