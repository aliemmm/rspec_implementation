return unless ENV["CI"] || ENV["COVERAGE"]

require "simplecov"
require "simplecov-cobertura"

def coverage_directory
  ENV["COVERAGE_DIR"] || "coverage"
end

def simplecov_formatter
  if ENV["CI"]
    SimpleCov::Formatter::CoberturaFormatter
  else
    SimpleCov::Formatter::HTMLFormatter
  end
end

SimpleCov.start "rails" do
  add_group "Services", "app/services"
  add_group "Queries", "app/queries"

  add_filter "/cookbooks/"
  add_filter "/deploy/"
  add_filter "/lib/tasks/"
  add_filter "/vendor/"

  formatter simplecov_formatter
  coverage_dir coverage_directory
end
