require "thor"
require "http"

module CodeshipMigrateToGithubApp
  class CLI < Thor

    CODESHIP_JSON_HEADER = "application/json"
    GITHUB_JSON_HEADER = "application/vnd.github.v3+json"

    CODESHIP_AUTH_URL = "https://api.codeship.com/v2/auth"
    GITHUB_ORGS_URL = "https://api.github.com/user/orgs"
    CODESHIP_MIGRATION_INFO_URL = "https://api.codeship.com/v2/github_migration_info"

    attr_accessor :codeship_token, :github_org, :codeship_migration_info

    def self.exit_on_failure?
      true
    end

    desc "start", "Convert projects to use Github app"
    long_desc <<-LONGDESC
      `codeship_migrate_to_github_app run` will convert your CodeShip projects
      utilizing the legacy Github Services to use the CodeShip Github App.
    LONGDESC
    option :codeship_user, banner: 'Codeship user name', type: :string, required: :true
    option :codeship_pass, banner: 'Codeship password', type: :string, required: :true
    option :github_token, banner: 'Github personal access token', type: :string, required: :true
    def start
      validate_github_credentials(options[:github_token])
      fetch_codeship_token(options[:codeship_user], options[:codeship_pass])
      fetch_migration_info
      # migrate
      puts "Migrated!"
    end

    no_commands do
      def fetch_codeship_token(user, pass)
        response = HTTP.headers(accept: CODESHIP_JSON_HEADER).basic_auth(user: user, pass: pass).post(CODESHIP_AUTH_URL)
        if response.code == 200
          @codeship_token = response.parse["access_token"]
        else
          raise Thor::Error.new "Error authenticating to CodeShip: #{response.code}: #{response.to_s}"
        end
      end

      def validate_github_credentials(token)
        response = HTTP.headers(accept: GITHUB_JSON_HEADER).auth("token #{token}").get(GITHUB_ORGS_URL)
        unless response.code == 200
          raise Thor::Error.new "Error authenticating to Github: #{response.code}: #{response.to_s}"
        end
      end

      def fetch_migration_info
        # Call private api on Mothership, get pairs of installation_id/repo_id
        response = HTTP.headers(accept: CODESHIP_JSON_HEADER).auth("token #{@codeship_token}").get(CODESHIP_MIGRATION_INFO_URL)
        unless response.code == 200
          raise Thor::Error.new "Error retreiving migration info from CodeShip: #{response.code}: #{response.to_s}"
        end
      end

      def migrate
        # Think codeship_migration_info will look like:
        # [
        #   {
        #   "installation_id": "123",
        #   "repositories": [
        #     { "repository_id": "7777" },
        #     { "repository_id": "8888" }
        #   ]
        #   },
        #   {
        #     "installation_id": "456",
        #     "repositories": [
        #       { "repository_id": "9999" }
        #     ]
        #   }
        # ]


        # for each installation_id/repo_id in @codeship_migration_info
        #   install github app
        # end
      end

    end
  end
end
