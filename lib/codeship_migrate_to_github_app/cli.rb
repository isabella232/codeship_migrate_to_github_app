require "thor"
require "http"

module CodeshipMigrateToGithubApp
  class CLI < Thor

    attr_accessor :codeship_token, :github_org_id, :github_installation_id

    def self.exit_on_failure?
      true
    end

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
      # fetch_codeship_projects
      # fetch_installation
      # migrate
      puts "Hello world!"
    end

    no_commands do
      def validate_arguments
        validate_codeship_credentials(options[:codeship_user], options[:codeship_pass])
        validate_github_credentials_and_org(options[:github_token], options[:github_org])
      end

      def validate_codeship_credentials(user, pass)
        response = HTTP.headers(accept: "application/json").basic_auth(user: user, pass: pass).post("https://api.codeship.com/v2/auth")
        if response.code == 200
          @codeship_token = response.parse["access_token"]
        else
          raise Thor::Error.new "Error authenticating to CodeShip: #{response.code}: #{response.to_s}"
        end
      end

      def validate_github_credentials_and_org(token, org)
        response = HTTP.headers(accept: "application/vnd.github.v3+json").auth("token #{token}").get("https://api.github.com/user/orgs")
        if response.code == 200
          # Need to rework this... match org name AND get org_id at same point
          organizations = response.parse.collect{|org| org['login'].downcase }
          if organizations.include?(org.downcase)
            # record org id
          else
            raise Thor::Error.new "Github organization not found in authorized orgs: #{organizations.join(', ')}"
          end
        else
          raise Thor::Error.new "Error authenticating to Github: #{response.code}: #{response.to_s}"
        end
      end

    end
  end
end
