# frozen_string_literal: true

class Workspace::Member < ApplicationRecord
  OWNER = "owner"
  ADMIN = "admin"
  COLLABORATOR = "collaborator"

  belongs_to :workspace, optional: true

  has_many :comments, dependent: :destroy
  has_many :assigned_tasks, foreign_key: :assigned_member_id, dependent: :nullify, class_name: "Task"
  has_many :initiated_transfers, foreign_key: :initiated_by_id, dependent: :destroy, class_name: "List::Transfer"

  enum :role, { owner: OWNER, admin: ADMIN, collaborator: COLLABORATOR }

  validates :uuid,     presence: true, format: { with: UUID::REGEXP }, uniqueness: true
  validates :username, presence: true, format: { with: Persona::USERNAME }
  validates :email,    presence: true, format: { with: Persona::EMAIL }

  def initials = Persona.initials(email: email, username: username)
end
