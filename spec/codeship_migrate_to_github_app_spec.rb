RSpec.describe CodeshipMigrateToGithubApp do
  it "has a version number" do
    expect(CodeshipMigrateToGithubApp::VERSION).not_to be nil
  end
end

RSpec.describe CodeshipMigrateToGithubApp::CLI do
  let(:run) { described_class.start }

  it "prints hello world" do
    expect{run}.to output("Hello world").to_stdout
  end
end
