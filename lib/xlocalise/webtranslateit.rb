require 'net/http'
require 'net/http/post/multipart'
require 'json'

module Xlocalise
	class WebtranslateIt

		attr_reader :http
		attr_reader :key, :source_locale, :master_file_id

		def initialize(key)
			@key = key

			@http = Net::HTTP.new("webtranslateit.com", 443)
			@http.use_ssl = true

			@http.request(Net::HTTP::Get.new("/api/projects/#{@key}")) {|response|
				project = JSON.parse(response.body)["project"]
				@source_locale = project["source_locale"]["code"]
				project["project_files"].each {|file|
					if file["locale_code"] == @source_locale
						@master_file_id = file["id"]
						break
					end
				}
				raise "Could not find master file for source locale #{@source_locale}" if @master_file_id.nil?
			}
		end

		def push_master(file, override = true)
			request = Net::HTTP::Put::Multipart.new("/api/projects/#{@key}/files/#{@master_file_id}/locales/#{@source_locale}", {
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
		end

		def pull(file, locale)
			http.request(Net::HTTP::Get.new("/api/projects/#{@key}/files/#{master_file_id}/locales/#{locale}")) {|response|
				file.write(response.body)
			}
		end

	end
end
