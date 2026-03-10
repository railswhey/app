# frozen_string_literal: true

CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Brakeman", "bin/brakeman", "--quiet", "--no-pager"
  step "Security: Gem audit", "bin/bundler-audit", "check", "--update"
  step "Quality: Rubycritic", "bin/rails", "rubycritic"
  step "Tests: Rails", "bin/rails", "test"
end
