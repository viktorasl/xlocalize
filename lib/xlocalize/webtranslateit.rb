require 'net/http'
require 'net/http/post/multipart'
require 'json'

module Xlocalize
  class WebtranslateIt

    attr_reader :http
    attr_reader :key, :source_locale

    attr_reader :xliff_file_id
    attr_reader :plurals_file_id

    def initialize(key)
      @key = key

      @http = Net::HTTP.new("webtranslateit.com", 443)
      @http.use_ssl = true

      @http.request(Net::HTTP::Get.new("/api/projects/#{@key}")) {|response|
        project = JSON.parse(response.body)["project"]
        @source_locale = project["source_locale"]["code"]
        project["project_files"].each {|file|
          next if file["locale_code"] != @source_locale
          @xliff_file_id = file["id"] if file['name'].end_with? '.xliff'
          @plurals_file_id = file["id"] if file['name'] == 'plurals.yaml'
        }
        raise "Could not find master xliff file for source locale #{@source_locale}" if @xliff_file_id.nil?
      }
    end

    def push_master(file, plurals_file, override = true)
      # uploding master xliff file
      request = Net::HTTP::Put::Multipart.new("/api/projects/#{@key}/files/#{@xliff_file_id}/locales/#{@source_locale}", {
        "file" => UploadIO.new(file, "text/plain", file.path),
        "merge" => !override,
        "ignore_missing" => true,
        "label" => "",
        "low_priority" => false })

      @http.request(request) {|res|
        if !res.code.to_i.between?(200, 300)
          raise JSON.parse(res.body)["error"]
        end
      }

      if @plurals_file_id.nil?
        # /api/projects/:project_token/files [POST]
        request = Net::HTTP::Put::Multipart.new("/api/projects/#{@key}/files", {
          "file" => UploadIO.new(file, "text/plain", plurals_file.path),
          "name" => "plurals.yaml",
          "low_priority" => false
        })
        @http.request(request)
      else
        # /api/projects/:project_token/files/:master_project_file_id/locales/:locale_code [PUT]
        request = Net::HTTP::Post::Multipart.new("/api/projects/#{@key}/files/#{@plurals_file_id}/locales/#{@source_locale}", {
          "file" => UploadIO.new(plurals_file, "text/plain", plurals_file.path),
          "merge" => !override,
          "ignore_missing" => true,
          "label" => "",
          "low_priority" => false
        })
        @http.request(request)
      end
    end

    def pull(file, locale)
      # downloading master xliff file
      http.request(Net::HTTP::Get.new("/api/projects/#{@key}/files/#{@xliff_file_id}/locales/#{locale}")) {|response|
        file.write(response.body)
      }
    end

  end
end
