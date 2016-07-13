require 'xlocalise/webtranslateit'
require 'colorize'
require 'nokogiri'

module Xlocalise
  class Executor

		def locale_file_name(locale)
			return "#{locale}.xliff"
		end

		def export_master(wti, project, target, excl_prefix, master_lang)
			master_file_name = locale_file_name(master_lang)
			
			system "xcodebuild -exportLocalizations -localizationPath ./ -project #{project}"
			purelyze(master_file_name, target, excl_prefix)

      # Pushing master file to WebtranslateIt
      begin
        puts "Uploading master file to WebtranslateIt"
        File.open(master_file_name, "r") {|file|
          wti.push_master(file)
          puts "Done.".green
        }
      rescue => err
        puts err.to_s.red
      end if !wti.nil?
		end

		def purelyze(locale_file_name, target, excl_prefix)
			target_prefix = "#{target}/"
			doc = Nokogiri::XML(open(locale_file_name))

			puts "Removing all files not matching required targets"
			doc.xpath("//xmlns:file").each { |node|
				fname = node["original"]
				node.remove if !fname.start_with?(target_prefix) || !fname.include?(".lproj/")
			}

			puts "Removing trans-unit's having reserverd prefix in their sources"
			doc.xpath("//xmlns:source").each { |node|
				node.parent.remove if node.content.start_with?(excl_prefix)
			}

			puts "Removing all files having no trans-unit elements after removal"
			doc.xpath("//xmlns:body").each { |node|
				node.parent.remove if node.elements.count == 0
			}

			puts "Writing modified XLIFF file to #{locale_file_name}"
			File.open(locale_file_name, "w") {|file| file.write(doc.to_xml) }
		end

    def download(wti, locales)
      begin
        locales.each do |locale|
          puts "Downloading localised file for #{locale} translation"
          File.open("#{locale}.xliff", "w") {|file|
            wti.pull(file, locale)
            puts "Done.".green
          }
        end
      rescue => err
        puts err.to_s.red
      end
    end
  end
end
