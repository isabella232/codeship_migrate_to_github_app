require 'spec_helper'

RSpec.describe CodeshipMigrateToGithubApp do
  it "has a version number" do
    expect(CodeshipMigrateToGithubApp::VERSION).not_to be nil
  end
end

RSpec.describe CodeshipMigrateToGithubApp::CLI, :type => :aruba do
  before(:each) { run('bin/codeship_migrate_to_github_app') }
  let(:command) { find_command("bin/codeship_migrate_to_github_app") }

  before(:each) { stop_all_commands }

  it { expect(command).to be_successfully_executed }
  it { expect(last_command_started.stdout).to eq "Hello world" }
end
