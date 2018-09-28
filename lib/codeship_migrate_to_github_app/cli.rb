# frozen_string_literal: true

require "thor"
require "http"

module CodeshipMigrateToGithubApp
  class CLI < Thor

    CODESHIP_JSON_HEADER = "application/json"
    GITHUB_JSON_HEADER = "application/vnd.github.v3+json"
    GITHUB_INSTALLATIONS_PREVIEW_HEADER = "application/vnd.github.v3+json, application/vnd.github.machine-man-preview+json"

    CODESHIP_AUTH_URL = "https://api.codeship.com/v2/auth"
    GITHUB_ORGS_URL = "https://api.github.com/user/orgs"
    CODESHIP_MIGRATION_INFO_URL = "https://api.codeship.com/v2/internal/github_app_migration"
    GITHUB_INSTALL_URL = "https://api.github.com/user/installations/{installation_id}/repositories/{repository_id}"
    GITHUB_LIST_HOOKS_URL = "https://api.github.com/repos/{owner}/{repo}/hooks"
    GITHUB_DELETE_HOOK_URL = "https://api.github.com/repos/{owner}/{repo}/hooks/{hook_id}"

    attr_accessor :codeship_token, :github_org, :codeship_migration_info, :errors

    def self.exit_on_failure?
      true
    end

    desc "start", "Convert projects to use Github app"
    long_desc <<-LONGDESC
      `codeship_migrate_to_github_app run` will convert your CodeShip projects
      utilizing the legacy Github Services to use the CodeShip Github App.
    LONGDESC
    option :codeship_user, banner: 'CodeShip user name', type: :string, required: :true
    option :codeship_pass, banner: 'CodeShip password', type: :string, required: :true
    option :github_token, banner: 'Github personal access token', type: :string, required: :true
    def start
      setup
      validate_github_credentials(options[:github_token])
      fetch_codeship_token(options[:codeship_user], options[:codeship_pass])
      fetch_migration_info
      migrate
      report
    end

    no_commands do
      def setup
        @errors = Array.new
      end

      def fetch_codeship_token(user, pass)
        response = HTTP.headers(accept: CODESHIP_JSON_HEADER).basic_auth(user: user, pass: pass).post(CODESHIP_AUTH_URL)
        unless response.code == 200
          raise Thor::Error.new "Error authenticating to CodeShip: #{response.code}: #{response.to_s}"
        end
        @codeship_token = response.parse["access_token"]
      end

      def validate_github_credentials(token)
        response = HTTP.headers(accept: GITHUB_JSON_HEADER).auth("token #{token}").get(GITHUB_ORGS_URL)
        unless response.code == 200
          raise Thor::Error.new "Error authenticating to Github: #{response.code}: #{response.to_s}"
        end
        @github_token = token
      end

      def fetch_migration_info
        response = HTTP.headers(accept: CODESHIP_JSON_HEADER).auth("token #{@codeship_token}").get(CODESHIP_MIGRATION_INFO_URL)
        unless response.code == 200
          raise Thor::Error.new "Error retrieving migration info from CodeShip: #{response.code}: #{response.to_s}"
        end

        @codeship_migration_info = response.parse&.fetch("installations")&.fetch("installations")
      end

      def migrate
        @codeship_migration_info.each do |installation|
          installation["repositories"].each do |repo|
            response = HTTP.headers(accept: GITHUB_INSTALLATIONS_PREVIEW_HEADER)
                           .auth("token #{@github_token}")
                           .put(github_install_url(installation["installation_id"], repo["repository_id"]))
            unless response.code == 204
              @errors << repo["repository_name"]
            end
            remove_legacy_service(repo["repository_name"])
          end
        end
      end

      def github_install_url(installation_id, repo_id)
        GITHUB_INSTALL_URL.sub('{installation_id}', installation_id.to_s).sub('{repository_id}', repo_id.to_s)
      end

      def remove_legacy_service(repo_name)
        owner, repo = parse_repo_name(repo_name)

        hook_id = find_legacy_codeship_hook(owner, repo)
        if hook_id
          delete_hook(owner, repo, hook_id)
        end
      end

      def find_legacy_codeship_hook(owner, repo)
        response = HTTP.headers(accept: GITHUB_JSON_HEADER)
                       .auth("token #{@github_token}")
                       .get(github_list_hooks_url(owner, repo))
        if response.code == 200
          hook = response.parse.find do |hook|
            hook["name"] == 'codeship'
          end
        end
        hook&.fetch("id")
      end

      def delete_hook(owner, repo, hook_id)
        response = HTTP.headers(accept: GITHUB_JSON_HEADER)
                       .auth("token #{@github_token}")
                       .delete(github_delete_hook_url(owner, repo, hook_id))
      end

      def parse_repo_name(repo_name)
         repo_name.split('/')
      end

      def github_list_hooks_url(owner, repo)
        GITHUB_LIST_HOOKS_URL.sub('{owner}', owner).sub('{repo}', repo)
      end

      def github_delete_hook_url(owner, repo, hook_id)
        GITHUB_DELETE_HOOK_URL.sub('{owner}', owner).sub('{repo}', repo).sub('{hook_id}', hook_id.to_s)
      end


      def report
        unless @errors.empty?
          puts "Couldn't install the CodeShip Github app for some repositories, please make the Github token you are \
          using has admin rights to your Github organization. For help, contact supoprt at https://helpdesk.codeship.com"
          puts "Error migrating the following repos:"
          @errors.each do |repo_name|
            puts "\t#{repo_name}"
          end
        end
        if @codeship_migration_info.empty?
          puts "No migration required"
        else
          puts "Migration complete!"
        end
      end
    end
  end
end
