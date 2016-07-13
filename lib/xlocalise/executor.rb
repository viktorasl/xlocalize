require 'nokogiri'

module Xlocalise
  class Executor
    attr_reader :project, :taget, :master_lang, :excl_prefix

		def initialize(project, target, excl_prefix, master_lang)
			@project = project
			@target = target
			@excl_prefix = excl_prefix
			@master_lang = master_lang
		end

		def locale_file_name(locale)
			return "#{locale}.xliff"
		end

		def export_master
			master_file_name = locale_file_name(@master_lang)
			
			system "xcodebuild -exportLocalizations -localizationPath ./ -project #{@project}"
			purelyze(master_file_name)
		end

		def purelyze(locale_file_name)
			target_prefix = "#{@target}/"
			doc = Nokogiri::XML(open(locale_file_name))

			puts "Removing all files not matching required targets"
			doc.xpath("//xmlns:file").each { |node|
				fname = node["original"]
				node.remove if !fname.start_with?(target_prefix) || !fname.include?(".lproj/")
			}

			puts "Removing trans-unit's having reserverd prefix in their sources"
			doc.xpath("//xmlns:source").each { |node|
				node.parent.remove if node.content.start_with?(@excl_prefix)
			}

			puts "Removing all files having no trans-unit elements after removal"
			doc.xpath("//xmlns:body").each { |node|
				node.parent.remove if node.elements.count == 0
			}

			puts "Writing modified XLIFF file to #{locale_file_name}"
			File.open(locale_file_name, "w") {|file| file.write(doc.to_xml) }
		end

		def export(locales)
			exportLanguages = locales.map {|locale| "-exportLanguage #{locale}"}.join(" ")
			system "xcodebuild -exportLocalizations -localizationPath ./ -project #{@project} #{exportLanguages}"

			locales.each {|locale|
				purelyze(locale_file_name(locale))
			}
		end
  end
end
