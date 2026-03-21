# frozen_string_literal: true

module Persona
  EMAIL = ::URI::MailTo::EMAIL_REGEXP
  USERNAME = /\A[a-zA-Z0-9_]+\z/

  def self.initials(email:, username:)
    name = username.to_s

    return name[0, 2].upcase if name.present?

    parts = email.to_s.split("@").first.to_s.split(/[._-]/)

    parts.size >= 2 ? "#{parts[0][0]}#{parts[1][0]}".upcase : email.to_s[0, 2].upcase
  end
end
