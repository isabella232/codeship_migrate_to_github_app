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
  let(:github_org) { "joshco" }
  let(:github_token) { "abc123" }

  let(:args) { ["start", "--codeship-user=#{codeship_user}",
                "--codeship-pass=#{codeship_pass}",
                "--github-org=#{github_org}",
                "--github-token=#{github_token}"]
             }

  let(:command) { CodeshipMigrateToGithubApp::CLI.start(args) }

  let(:urls) do
    {
        codeship_auth: "https://api.codeship.com/v2/auth",
        github_orgs: "https://api.github.com/user/orgs"
    }
  end

  describe "#start" do
    before(:each) do
      stub_request(:post, urls[:codeship_auth]).to_return(status: 200, headers: JSON_TYPE, body: '{"access_token": "abc123"}')
      stub_request(:get, urls[:github_orgs]).to_return(status: 200, headers: JSON_TYPE, body: '[{"login": "joshco", "id": 123, "url": "https://api.github.com/orgs/joshco"}]')
    end

    context "valid arguments" do
      it { expect{command}.to_not raise_error }
      it { expect{command}.to output(a_string_including("Hello world!")).to_stdout  }
    end

    context "codeship username not found" do
      before(:each) do
        stub_request(:post, urls[:codeship_auth]).to_return(status: 401, headers: JSON_TYPE, body: '{"errors":["Unauthorized"]}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error authenticating to CodeShip: 401")).to_stderr  }
    end

    context "codeship password wrong" do
      before(:each) do
        stub_request(:post, urls[:codeship_auth]).to_return(status: 401, headers: JSON_TYPE, body: '{"errors":["Unauthorized"]}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error authenticating to CodeShip: 401")).to_stderr  }
    end

    context "invalid Github token" do
      before(:each) do
        stub_request(:get, urls[:github_orgs]).to_return(status: 401, headers: JSON_TYPE, body: '{"message": "Requires authentication", "documentation_url": "https://developer.github.com/v3/orgs/#list-your-organizations"}')
      end

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Error authenticating to Github: 401")).to_stderr  }
    end

    context "invalid Github organization" do
      let(:github_org) { "Vandelay" }

      it { expect{command}.to raise_error(SystemExit) }
      it { expect{begin; command; rescue SystemExit; end}.to output(a_string_including("Github organization #{github_org} not found in authorized orgs")).to_stderr  }
    end
  end
end
