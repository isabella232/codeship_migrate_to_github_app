require 'spec_helper'

RSpec.describe CodeshipMigrateToGithubApp do
  it "has a version number" do
    expect(CodeshipMigrateToGithubApp::VERSION).not_to be nil
  end
end

RSpec.describe CodeshipMigrateToGithubApp::CLI, :type => :aruba do
  let(:cli) { "bin/codeship_migrate_to_github_app start \
                --codeship-user='#{codeship_user}' \
                --codeship-pass='#{codeship_pass}' \
                --github-org='#{github_org}' \
                --github-token='##{github_token}'" }
  before(:each) { run(cli) }
  let(:command) { find_command(cli) }

  let(:codeship_user) { "josh" }
  let(:codeship_pass) { "s3cr3t" }
  let(:github_org) { "joshco" }
  let(:github_token) { "abc123" }

  before(:each) { stop_all_commands }

  describe "#start" do
    context "valid arguments" do
      it { expect(command).to be_successfully_executed }
      it { expect(last_command_started.stdout).to include "Hello world" }
    end

    # context "codeship username not found" do
    #   it { expect(command).to_not be_successfully_executed }
    #   it { expect(last_command_started.stdout).to include "Invalid CodeShip credentials" }
    # end
    #
    # context "codeship password wrong" do
    #   it { expect(command).to_not be_successfully_executed }
    #   it { expect(last_command_started.stdout).to include "Invalid CodeShip credentials" }
    # end
    #
    # context "invalid Github token" do
    #   it { expect(command).to_not be_successfully_executed }
    #   it { expect(last_command_started.stdout).to include "Invalid Github credentials" }
    # end
    #
    # context "invalid Github organization" do
    #   it { expect(command).to_not be_successfully_executed }
    #   it { expect(last_command_started.stdout).to include "Invalid Github organization" }
    # end
  end
end
