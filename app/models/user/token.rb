# frozen_string_literal: true

class User::Token < ApplicationRecord
  belongs_to :user

  attribute :long, :string

  before_validation :refresh, on: :create

  validates :long, presence: true, length: { is: Secret::LONG_LENGTH }
  validates :short, presence: true, length: { is: Secret::SHORT_LENGTH }

  def value
    Secret.new(short:, long:).value
  end

  def refresh(secure_random: SecureRandom)
    Secret.new.generate(secure_random:).then do |secret|
      self.short = secret.short
      self.long = secret.long
      self.checksum = Secret.checksum(short:, long:)
    end
  end

  def refresh!(...)
    attempts ||= 1

    refresh(...).then { save! }.then { self }
  rescue ActiveRecord::RecordNotUnique
    retry if (attempts += 1) <= 3
  end
end
