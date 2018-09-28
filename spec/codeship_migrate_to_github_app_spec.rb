# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodeshipMigrateToGithubApp do
  it "has a version number" do
    expect(CodeshipMigrateToGithubApp::VERSION).not_to be nil
  end
end

RSpec.describe CodeshipMigrateToGithubApp::CLI do
  JSON_TYPE = {"Content-Type" => "application/json"}

  let(:codeship_user) { "josh" }
  let(:codeship_pass) { "s3cr3t" }
  let(:github_token) { "abc123" }

  let(:args) { ["start", "--codeship-user=#{codeship_user}",
                "--codeship-pass=#{codeship_pass}",
                "--github-token=#{github_token}" ]
            }

  let(:command) { CodeshipMigrateToGithubApp::CLI.start(args) }

  let(:urls) do
    {
        codeship_auth: "https://api.codeship.com/v2/auth",
        github_orgs: "https://api.github.com/user/orgs",
        codeship_migration: "https://api.codeship.com/v2/internal/github_app_migration",
        github_install: Addressable::Template.new("https://api.github.com/user/installations/{installation_id}/repositories/{repository_id}"),
        github_hooks: Addressable::Template.new("https://api.github.com/repos/{owner}/{repo}/hooks")
   }
  end

  describe "#start" do
    before(:each) do
      stub_request(:post, urls[:codeship_auth]).to_return(status: 200, headers: JSON_TYPE, body: '{"access_token": "abc123", "organizations":[{"uuid":"86ca6be0-413d-0134-079f-1e81b891aacf","name":"joshco"},{"uuid":"c00d11a0-383b-0136-dfac-0aa9c93fd8f3","name":"partial-match-76"}]}')
      stub_request(:get, urls[:github_orgs]).to_return(status: 200, headers: JSON_TYPE, body: '[{"login": "joshco", "id": 123, "url": "https://api.github.com/orgs/joshco"}]')
      stub_request(:get, urls[:codeship_migration]).to_return(status: 200, headers: JSON_TYPE, body: '{"installations":{"installations":[{"installation_id":"123","repositories":[{"repository_id":"7777","repository_name":"foo/bar"},{"repository_id":"8888","repository_name":"foo/foo"}]},{"installation_id":"456","repositories":[{"repository_id":"9999","repository_name":"bar/bar"}]}]}}')
      stub_request(:put, urls[:github_install]).to_return(status: 204, headers: JSON_TYPE, body: '')
      stub_request(:get, urls[:github_hooks]).to_return(status: 200, headers: JSON_TYPE, body: '[]')
    end

    context "valid arguments" do
      it { expect{command}.to_not raise_error }
      it { expect(command).to have_requested(:put, "https://api.github.com/user/installations/123/repositories/7777").once }
      it { expect(command).to have_requested(:put, "https://api.github.com/user/installations/123/repositories/8888").once }
      it { expect(command).to have_requested(:put, "https://api.github.com/user/installations/456/repositories/9999").once }
      it { expect{command}.to output(a_string_including("Migration complete!")).to_stdout }
    end

    context "legacy hook exists" do
      before(:each) do
        stub_request(:get, urls[:github_hooks]).to_return({status: 200, headers: JSON_TYPE, body: '[{"type":"Repository","id":45678,"name":"codeship","active":true,"events":["push"],"config":{"project_uuid":"abc123"}}]'}, {status: 200, headers: JSON_TYPE, body: '[]'})
        stub_request(:delete, "https://api.github.com/repos/foo/bar/hooks/45678").to_return({status: 204, headers: JSON_TYPE, body:''})
      end

      it { expect{command}.to_not raise_error }
      it { expect(command).to have_requested(:delete, "https://api.github.com/repos/foo/bar/hooks/45678").once }
      it { expect{command}.to output(a_string_including("Migration complete!")).to_stdout }
    end

    context "codeship username not found" do
      before(:each) do
        stub_request(:post, urls[:codeship_auth]).to_return(status: 401, headers: JSON_TYPE, body: '{"errors":["Unauthorized"]}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error authenticating to CodeShip: 401")).to_stderr }
    end

    context "codeship password wrong" do
      before(:each) do
        stub_request(:post, urls[:codeship_auth]).to_return(status: 401, headers: JSON_TYPE, body: '{"errors":["Unauthorized"]}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error authenticating to CodeShip: 401")).to_stderr }
    end

    context "invalid Github token" do
      before(:each) do
        stub_request(:get, urls[:github_orgs]).to_return(status: 401, headers: JSON_TYPE, body: '{"message": "Requires authentication", "documentation_url": "https://developer.github.com/v3/orgs/#list-your-organizations"}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error authenticating to Github: 401")).to_stderr }
    end

    context "error contacting CodeShip for migration information" do
      before(:each) do
        stub_request(:get, urls[:codeship_migration]).to_return(status: 500, headers: JSON_TYPE, body: '{"errors":["Unknown system error"]}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error retrieving migration info from CodeShip: 500")).to_stderr }
    end

    context "error performing migration on a repo" do
      before(:each) do
        stub_request(:put, "https://api.github.com/user/installations/123/repositories/8888").to_return(status: 500, headers: JSON_TYPE, body: nil)
      end

      it { expect{command}.to_not raise_error }
      it { expect{command}.to output(a_string_including("Couldn't install the CodeShip Github app for some repositories")).to_stdout }
      it { expect{command}.to output(a_string_including("Error migrating the following repos:")).to_stdout }
      it { expect{command}.to output(a_string_including("foo/foo")).to_stdout }
      it { expect{command}.to output(a_string_including("Migration complete!")).to_stdout }
    end

    context "not found error/not authorized during installation" do
      before(:each) do
        stub_request(:put, "https://api.github.com/user/installations/123/repositories/8888").to_return(status: 404, headers: JSON_TYPE, body: nil)
      end

      it { expect{command}.to_not raise_error }
      it { expect{command}.to output(a_string_including("Couldn't install the CodeShip Github app for some repositories")).to_stdout }
      it { expect{command}.to output(a_string_including("Error migrating the following repos:")).to_stdout }
      it { expect{command}.to output(a_string_including("foo/foo")).to_stdout }
      it { expect{command}.to output(a_string_including("Migration complete!")).to_stdout }
    end

    context "no repos to migrate" do
      before(:each) do
        stub_request(:get, urls[:codeship_migration]).to_return(status: 200, headers: JSON_TYPE, body: '{"installations":{"installations":[]}}')
      end

      it { expect{command}.to_not raise_error }
      it { expect{command}.to output(a_string_including("No migration required")).to_stdout }
    end
  end
end
