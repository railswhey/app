# frozen_string_literal: true

module User::Registration
  def self.call(params)
    user = User.new(params)

    user.uuid = SecureRandom.uuid

    return user unless user.valid?

    user.transaction do
      user.save!
      user.create_token!
    end

    user
  rescue ActiveRecord::RecordInvalid
    user
  end
end
