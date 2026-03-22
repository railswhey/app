# frozen_string_literal: true

class AddUUIDToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :uuid, :string
    add_index :users, :uuid, unique: true
  end
end
