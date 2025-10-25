CI.run do
  step "Lint: StandardRB", "bundle exec standardrb"
  step "Lint: StandardJS", "yarn lint"
  step "Lint: YAML", "yarn lint:yml"
  step "Lint: ERB", "bundle exec erb_lint --lint-all"

  step "Setup: Build assets", "bin/vite build --clear --mode=test"

  step "Test: Rails", "bin/rails test"
  step "Test: System", "bin/rails test:system"
end
