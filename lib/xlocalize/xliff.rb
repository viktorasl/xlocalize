require 'nokogiri'
require 'plist'
require 'pathname'

class String
  def start_with_either?(prefixes)
    prefixes.each do |prefix|
      return true if start_with?(prefix)
    end
    return false
  end
end
  
module Xlocalize
  class ::Nokogiri::XML::Document

    def filter_not_target_files(targets)
      prefixes = targets.map { |t| "#{t}/" }
      self.xpath("//xmlns:file").each { |node|
        fname = node["original"]
        node.remove if !fname.start_with_either?(prefixes) || !fname.include?(".lproj/")
      }
    end

    def filter_trans_units(prefix)
      self.xpath("//xmlns:source").each { |node|
        node.parent.remove if node.content.start_with?(prefix)
      }
    end

    def filter_plurals(project)
      plurals = {}
      self.xpath("//xmlns:file").each { |node|
        fname = node["original"]
        next if !fname.end_with?(".strings")
        fname_stringsdict = fname << 'dict'
        file_full_path = Pathname.new(project).split.first.to_s  << '/' << fname_stringsdict
        next if !File.exist?(file_full_path)
        
        translations = {}
        Plist::parse_xml(file_full_path).each do |key, val|
          transl = val["value"].select { |k, _| ['zero', 'one', 'two', 'few', 'many', 'other'].include?(k) }
          translations[key] = transl
          sel = 'body > trans-unit[id="' << key << '"]'
          node.css(sel).remove
        end
        plurals[fname_stringsdict] = translations
      }
      plurals.each { |k, _| self.css('file[original="' << k << '"]').remove }
      return plurals
    end

    def filter_empty_files
      self.xpath("//xmlns:body").each { |node|
        node.parent.remove if node.elements.count == 0
      }
    end

    def filter_duplicate_storyboard_xib_files
      all_files = self.xpath("//xmlns:file").map { |node| Pathname.new(node["original"]).split.last.to_s }
      self.xpath("//xmlns:file").each do |node|
        fname = Pathname.new(node["original"]).split.last.to_s
        if fname.end_with?(".strings")
          storyboard_fname = fname.sub(".strings", ".storyboard")
          xib_fname = fname.sub(".strings", ".xib")
          if all_files.include?(storyboard_fname) || all_files.include?(xib_fname)
            node.remove
          end
        end
      end
    end

    def unescape
      self.xpath("//xmlns:source").each do |src|
        src.content = src.content
          .gsub('\\"', '"')
          .gsub('\\\\n', '\n')
      end
    end

    def merge_on_top_of(original_doc)
      #original_doc = Nokogiri::XML(wti.pull(master_lang)['xliff'])
      original_xliff = original_doc.at_css('xliff')
      doc = self#Nokogiri::XML(File.open(master_file_name))
      doc.xpath("//xmlns:file").each { |node|
        fname = node["original"]
        original_file = original_doc.at_css('file[original="' << fname << '"] > body')
        if original_file then
          node.css('body > trans-unit').each { |unit|
            key = unit['id']
            original_unit = original_file.at_css('trans-unit[id="' << key << '"]')
            if !original_unit then
              original_file << unit
            end
          }
        else
          original_xliff << node
        end
      }
    end

    def cryptic_trans_units(exclude)
      file_units = {}
      cryptic_pattern = /[a-zA-Z0-9]{3}-[a-zA-Z0-9]{2}-[a-zA-Z0-9]{3}/
      self.xpath("//xmlns:file").each do |node|
        fname = node["original"]
        all_units = node.css('body > trans-unit').map { |unit| unit['id'] }
        cryptic_units = all_units.select do |key|
          is_excluded = (exclude[fname] || []).include?(key)
          !is_excluded && (key =~ cryptic_pattern)
        end
        file_units[fname] = cryptic_units if cryptic_units.any?
      end
      return file_units
    end
  end
end
