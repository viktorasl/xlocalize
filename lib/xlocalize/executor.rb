require 'xlocalize/webtranslateit'
require 'xlocalize/xliff'
require 'xlocalize/helper'
require 'xlocalize/importer'
require 'colorize'
require 'nokogiri'
require 'yaml'
require 'apfel'

module Xlocalize
  class Executor

    def plurals_file_name(locale)
      return locale_file_name(locale) << '_plurals.yml'
    end

    def locale_file_name(locale)
      return "#{locale}.xliff"
    end

    def export_master(wti, project, targets, excl_prefix, master_lang, exclude_units=[], no_cryptic)
      master_file_name = locale_file_name(master_lang)

      File.delete(master_file_name) if File.exist?(master_file_name)

      if Helper.xcode_at_least?(9)
        Kernel.system "xcodebuild -exportLocalizations -localizationPath ./ -project #{project}"
      else
        # hacky way to finish xcodebuild -exportLocalizations script, because
        # since Xcode7.3 & OS X Sierra script hangs even though it produces
        # xliff output
        # http://www.openradar.me/25857436
        Kernel.system "xcodebuild -exportLocalizations -localizationPath ./ -project #{project} & sleep 0"
        while !File.exist?(master_file_name) do
          sleep(1)
        end        
      end

      purelyze(master_lang, targets, excl_prefix, project, filer_ui_duplicates=Helper.xcode_at_least?(9.3), exclude_units)
      if no_cryptic then
        config_fname = '.xlocalize.yml'
        config = (YAML.load_file(config_fname) if File.file?(config_fname)) || {}
        allow_cryptic = config['allow_cryptic'] || {}
        
        doc = Nokogiri::XML(File.open(locale_file_name(master_lang)))
        cryptic_trans_units = doc.cryptic_trans_units(allow_cryptic)
        if !cryptic_trans_units.empty? then
          err_msg = "Found cryptic translation units\n"
          err_msg += cryptic_trans_units.map { |fname, units| "#{fname}" + "\n " + units.join("\n ") }.join("\n")
          raise err_msg
        end
      end

      if wti then
        original_doc = Nokogiri::XML(wti.pull(master_lang)['xliff'])
        Nokogiri::XML(File.open(master_file_name)).merge_on_top_of(original_doc)
        File.write(master_file_name, original_doc.to_xml)
      end
      push_master_file(wti, master_lang, master_file_name) if !wti.nil?
    end

    def push_master_file(wti, master_lang, master_file_name)
      # Pushing master file to WebtranslateIt
      begin
        puts "Uploading master file to WebtranslateIt"
        file = File.open(master_file_name, 'r')
        plurals_path = plurals_file_name(master_lang)
        plurals_file = File.exist?(plurals_path) ? File.open(plurals_path, 'r') : nil
        wti.push_master(file, plurals_file)
        puts "Done.".green
      rescue => err
        puts err.to_s.red
      ensure
        file.close unless file.nil?
        plurals_file.close unless plurals_file.nil?
      end if !wti.nil?
    end

    def purelyze(locale, targets, excl_prefix, project, filer_ui_duplicates=false, exclude_units)
      locale_file_name = locale_file_name(locale)
      doc = Nokogiri::XML(File.open(locale_file_name))

      puts "Removing all files not matching required targets" if $VERBOSE
      doc.filter_not_target_files(targets)
      puts "Removing trans-unit's having reserverd prefix in their sources" if $VERBOSE
      doc.filter_trans_units(excl_prefix)
      puts "Filtering plurals" if $VERBOSE
      plurals = doc.filter_plurals(project)
      puts "Removing excluded translation units" if $VERBOSE
      doc.xpath("//xmlns:trans-unit").each { |unit| unit.remove if exclude_units.include?(unit['id']) }
      puts "Removing all files having no trans-unit elements after removal" if $VERBOSE
      doc.filter_empty_files
      puts "Unescaping translation units" if $VERBOSE
      doc.unescape

      if filer_ui_duplicates
        puts "Filtering duplicate xib & storyboard translation files" if $VERBOSE
        doc.filter_duplicate_storyboard_xib_files
      end
      
      puts "Writing modified XLIFF file to #{locale_file_name}" if $VERBOSE
      File.open(locale_file_name, 'w') { |f| f.write(doc.to_xml) }
      if !plurals.empty?
        puts "Writing plurals to plurals YAML file" if $VERBOSE
        File.open(plurals_file_name(locale), 'w') { |f| f.write({locale => plurals}.to_yaml) }
      end
    end

    def out_list_of_translations_of_locale(wti, locale, translations)
      puts "Downloading translations for #{locale}"
      translations = wti.pull(locale)
      plurals_content = translations['plurals']

      out_list = [{
        "path" => "#{locale}.xliff",
        "content" => translations['xliff']
      }]
      out_list << {
        "path" => "#{locale}_plurals.yaml",
        "content" => plurals_content
      } if not plurals_content.nil?

      return out_list
    end

    def download(wti, locales)
      begin
        locales.each do |locale|
          translations = wti.pull(locale)
          
          out_list_of_translations_of_locale(wti, locale, translations).each do |out|
            File.open(out["path"], "w") do |file|
              file.write(out["content"])
              puts "Done saving #{out['path']}.".green
            end
          end
        end
      rescue => err
        puts err.to_s.red
      end
    end

    def localized_filename(file_name, locale)
      parts = file_name.split('/')
      name = ""
      parts.each_with_index do |part, idx|
        name += "/" if idx > 0
        if part.end_with?(".lproj")
          name += "#{locale}.lproj"
        elsif idx+1 == parts.count
          extension = (part.split('.')[1] == 'stringsdict') ? 'stringsdict' : 'strings'
          # TODO: join all parts till the last '.'
          name += "#{part.split('.')[0]}.#{extension}"
        else
          name += part
        end
      end
      return name
    end

    def import_xliff(fname)
      puts "Importing translations from #{fname}" if $VERBOSE
      Nokogiri::XML(File.open(fname)).xpath("//xmlns:file").each do |node|
        tr_fname = node["original"]
        source_lang = node["source-language"]
        target_lang = node["target-language"]
        
        localized_src_fname = localized_filename(tr_fname, source_lang)
        next if !File.exist?(localized_src_fname)

        translations_hash = Apfel.parse(localized_src_fname).to_hash
        importer = Importer.new
        importer.translate_from_node(translations_hash, node)

        f_content = importer.strings_content_from_translations_hash(translations_hash)
        target_fname = localized_filename(tr_fname, target_lang)
        File.open(target_fname, 'w') { |f| f.write(f_content) }
      end
    end

    def import_plurals_if_needed(locale)
      plurals_fname = "#{locale}_plurals.yaml"
      return if !File.exist?(plurals_fname)
      puts "Importing translations from #{plurals_fname}" if $VERBOSE
      plurals_yml = YAML.load_file(plurals_fname)
      plurals_yml[locale].each do |original_fname, trans_units|
        content = ''
        content << '<?xml version="1.0" encoding="UTF-8"?>' + "\n"
        content << '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' + "\n"
        content << '<plist version="1.0">' + "\n"

        fname = localized_filename(original_fname, locale)
        content << "<dict>\n"
        trans_units.each do |key, element|
          content << "\t<key>#{key}</key>\n"
          content << "\t<dict>\n"

          content << "\t\t<key>NSStringLocalizedFormatKey</key>\n"
          content << "\t\t<string>%\#@value@</string>\n"
          content << "\t\t<key>value</key>\n"
          content << "\t\t<dict>\n"
          element.each do |k, v|
            content << "\t\t\t<key>#{k}</key>\n"
            content << "\t\t\t<string>#{v}</string>\n"
          end
          content << "\t\t\t<key>NSStringFormatSpecTypeKey</key>\n"
          content << "\t\t\t<string>NSStringPluralRuleType</string>\n"
          content << "\t\t\t<key>NSStringFormatValueTypeKey</key>\n"
          content << "\t\t\t<string>d</string>\n"
          content << "\t\t</dict>\n"

          content << "\t</dict>\n"
        end
        content << "</dict>\n"
        content << "</plist>\n"

        File.open(fname, 'w') { |f| f.write content }
      end
    end

    def import(locales, allows_missing_files=false)
      puts 'Importing translations' if $VERBOSE
      locales.each do |locale|
        import_xliff("#{locale}.xliff")
        import_plurals_if_needed(locale)
        puts "Done #{locale}".green if $VERBOSE
      end
    end
  end
end
