
module Xlocalize
  class Importer

    def strings_content_from_translations_hash(translations_hash)
      result = StringIO.new
      translations_hash.each do |key, translations|
        translations.each do |target, note|
          result << "/* #{note} */\n" if note.length > 0
          result << "\"#{key}\" = #{target.inspect};\n\n"
        end
      end
      return result.string
    end

    def translate_from_node(translations, node)
      (node > "body > trans-unit").each do |trans_unit|
        key = trans_unit["id"]
        target = (trans_unit > "target").text
        note = (trans_unit > "note").text
        if translations.key?(key)
          translations[key] = { target => note }
        end
      end
    end
  end
end