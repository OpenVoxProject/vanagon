require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'yard'

desc 'Test Vanagon'
namespace :test do
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new do |task|
    task.rspec_opts = %(--format documentation --color --require spec_helper)
  end

  desc 'Test Vanagon and calculate test coverage'
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test:spec'].invoke
  end
end

desc 'Run RuboCop'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options << '--display-cop-names'
end

desc 'Generate doc using Yard'
YARD::Rake::YardocTask.new

desc 'Run all spec tests and linters'
task check: %w[test:spec rubocop]

task default: :check

begin
  require 'github_changelog_generator/task'

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = <<~HEADER.chomp
      # Changelog

      All notable changes to this project will be documented in this file.
    HEADER
    config.user = 'openvoxproject'
    config.project = 'vanagon'
    config.exclude_labels = %w[dependencies duplicate question invalid wontfix wont-fix modulesync skip-changelog]
    config.future_release = Gem::Specification.load("#{config.project}.gemspec").version
    config.since_tag = '0.53.0' # last tag from Perforce
  end
rescue LoadError
  task :changelog do
    abort('Run `bundle install --with release` to install the `github_changelog_generator` gem.')
  end
end
