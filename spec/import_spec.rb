require 'spec_helper'

describe Xlocalize::Executor do
  describe "#import_xliff" do
    describe "plurals not exist" do
      before(:each) do
        allow(File).to receive(:open).with("de.xliff").and_return(File.open("spec/fixtures/de/de.xliff"))
        allow(File).to receive(:exist?).with("de_plurals.yaml").and_return(false)
      end

      it "writes xliff translations to files" do
        file1 = StringIO.new
        file2 = StringIO.new
        expect(File).to receive(:exist?).with("path/to/strings/en.lproj/translations_file_one.strings").and_return(true)
        expect(Apfel).to receive(:parse).with("path/to/strings/en.lproj/translations_file_one.strings").and_return({"string_one" => {"The Book" => "Comment 1"}})
        expect(File).to receive(:open).with("path/to/strings/de.lproj/translations_file_one.strings", "w").and_yield(file1)
        expect(File).to receive(:exist?).with("path/to/strings/en.lproj/translations_file_two.strings").and_return(true)
        expect(Apfel).to receive(:parse).with("path/to/strings/en.lproj/translations_file_two.strings").and_return({"string_two" => {"A Train" => "Comment 2"}})
        expect(File).to receive(:open).with("path/to/strings/de.lproj/translations_file_two.strings", "w").and_yield(file2)

        Xlocalize::Executor.new.import(["de"])
        expect(file1.string).to eq(<<~END
        /* Comment 1 */
        "string_one" = "Ein Buch";

        END
        )
        expect(file2.string).to eq(<<~END
        /* Comment 2 */
        "string_two" = "Ein Zug";

        END
        )
      end

      it "skips missing files" do
        file = StringIO.new
        expect(File).to receive(:exist?).with("path/to/strings/en.lproj/translations_file_one.strings").and_return(true)
        expect(Apfel).to receive(:parse).with("path/to/strings/en.lproj/translations_file_one.strings").and_return({"string_one" => {"The Book" => "Comment 1"}})
        expect(File).to receive(:open).with("path/to/strings/de.lproj/translations_file_one.strings", "w").and_yield(file)
        expect(File).to receive(:exist?).with("path/to/strings/en.lproj/translations_file_two.strings").and_return(false)
        allow(Apfel).to receive(:parse).with("path/to/strings/en.lproj/translations_file_two.strings").and_raise

        Xlocalize::Executor.new.import(["de"])
      end
    end

    it "imports plurals if file exists" do
      empty_stub = File.open("spec/fixtures/empty.xliff")
      yaml_stub = YAML.load_file("spec/fixtures/de/plurals.yaml")

      expect(File).to receive(:exist?).with("de_plurals.yaml").and_return(true)
      expect(File).to receive(:open).with("de.xliff").and_return(empty_stub) 
      expect(YAML).to receive(:load_file).with("de_plurals.yaml").and_return(yaml_stub)
      file = StringIO.new
      expect(File).to receive(:open).with("path/to/plurals/de.lproj/screen.stringsdict", "w").and_yield(file)

      Xlocalize::Executor.new.import(["de"])
      expect(file.string).to eq(<<~END
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      \t<key>employees</key>
      \t<dict>
      \t\t<key>NSStringLocalizedFormatKey</key>
      \t\t<string>%\#@value@</string>
      \t\t<key>value</key>
      \t\t<dict>
      \t\t\t<key>one</key>
      \t\t\t<string>Mitarbeiter</string>
      \t\t\t<key>other</key>
      \t\t\t<string>Mitarbeiter</string>
      \t\t\t<key>NSStringFormatSpecTypeKey</key>
      \t\t\t<string>NSStringPluralRuleType</string>
      \t\t\t<key>NSStringFormatValueTypeKey</key>
      \t\t\t<string>d</string>
      \t\t</dict>
      \t</dict>
      </dict>
      </plist>
      END
      )
    end
  end
end
