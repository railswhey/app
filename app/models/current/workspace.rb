# frozen_string_literal: true

class Current::Workspace
  attr_reader :member

  delegate :id, :uuid, :tasks, :inbox, :search,
           :outgoing_transfers, :incoming_transfers,
           :present?, to: :record, allow_nil: true

  def initialize(record:, member:)
    @record = record
    @member = member
  end

  def lists = record&.lists || ::Workspace::List.none

  attr_reader :record
end
