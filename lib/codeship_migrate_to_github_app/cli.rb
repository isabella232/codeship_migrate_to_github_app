require "thor"
require "http"

module CodeshipMigrateToGithubApp
  class CLI < Thor

    CODESHIP_JSON_HEADER = "application/json"
    GITHUB_JSON_HEADER = "application/vnd.github.v3+json"

    CODESHIP_AUTH_URL = "https://api.codeship.com/v2/auth"
    GITHUB_ORGS_URL = "https://api.github.com/user/orgs"

    attr_accessor :codeship_token, :codeship_org, :github_org

    def self.exit_on_failure?
      true
    end

    desc "start", "Convert projects to use Github app"
    long_desc <<-LONGDESC
      `codeship_migrate_to_github_app run` will convert your CodeShip projects
      utilizing the legacy Github Services to use the CodeShip Github App. By default
      all CodeShip projects you have access to will be converted: supply a CodeShip
      organization name to only convert projects for a single CodeShip org.
    LONGDESC
    option :github_org, banner: 'Github organization name', type: :string, required: :true
    option :github_token, banner: 'Github personal access token', type: :string, required: :true
    option :codeship_user, banner: 'Codeship user name', type: :string, required: :true
    option :codeship_pass, banner: 'Codeship password', type: :string, required: :true
    option :codeship_org, banner: 'Codeship organization name to migrate', type: :string, required: :true
    def start
      validate_arguments
      fetch_github_installation
      # fetch_codeship_projects
      # migrate
      puts "Migrated!"
    end

    no_commands do
      def validate_arguments
        validate_codeship_credentials(options[:codeship_user], options[:codeship_pass], options[:codeship_org])
        validate_github_credentials_and_org(options[:github_token], options[:github_org])
      end

      def validate_codeship_credentials(user, pass, codeship_org_name)
        response = HTTP.headers(accept: CODESHIP_JSON_HEADER).basic_auth(user: user, pass: pass).post(CODESHIP_AUTH_URL)
        if response.code == 200
          @codeship_token = response.parse["access_token"]
          @codeship_org = fetch_codeship_org(response, codeship_org_name)
        else
          raise Thor::Error.new "Error authenticating to CodeShip: #{response.code}: #{response.to_s}"
        end
      end

      def validate_github_credentials_and_org(token, github_org_name)
        response = HTTP.headers(accept: GITHUB_JSON_HEADER).auth("token #{token}").get(GITHUB_ORGS_URL)
        if response.code == 200
          @github_org = fetch_github_org(response, github_org_name)
        else
          raise Thor::Error.new "Error authenticating to Github: #{response.code}: #{response.to_s}"
        end
      end

      def fetch_github_org(response, org_name)
        error = lambda {raise Thor::Error.new "Github organization #{org_name} not found in authorized orgs"}
        response.parse.find(error) { |org| org["login"] == org_name.downcase  }
      end

      def fetch_codeship_org(response, codeship_org_name)
        error = lambda { raise Thor::Error.new "CodeShip organization #{codeship_org_name} not found in this users organizations" }
        response.parse["organizations"].find(error) { |org| org["name"].include?(codeship_org_name.downcase) }
      end

      def fetch_github_installation
        # using our Github app's credentials, get installation id for the github_org
      end

      def fetch_codeship_projects
        # for each org in @codeship_orgs
        #   call codeship_api endpoint list_projects
        #   add projects to big_array (@codeship_projects maybe?)
        # end
      end

      def migrate
        # for each project in @codeship_projects
        #   install github app
        # end
      end

    end
  end
end
