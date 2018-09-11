require "thor"

module CodeshipMigrateToGithubApp
  class CLI < Thor

    desc "start", "Convert projects to use Github app"
    long_desc <<-LONGDESC
      `codeship_migrate_to_github_app run` will convert your CodeShip projects
      utilizing the legacy Github Services to use the CodeShip Github App.
    LONGDESC
    option :github_org, banner: 'Github organization name', type: :string, required: :true
    option :github_token, banner: 'Github personal access token', type: :string, required: :true
    option :codeship_user, banner: 'Codeship user name', type: :string, required: :true
    option :codeship_pass, banner: 'Codeship password', type: :string, required: :true
    def start
      validate_arguments
      puts "Hello world!"
    end

    def validate_arguments
      # validate_codeship_credentials
      # validate_github_credentials
      # validate_github_organization
    end


  end
end
