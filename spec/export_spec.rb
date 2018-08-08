require 'spec_helper'
require 'fileutils'
require 'nokogiri'
require 'xlocalize/helper'

describe Xlocalize::Executor do
  describe 'when exporting' do

    it 'not contains excluded translations units in xliff' do
      xliff = <<-eos
      <?xml version="1.0" encoding="UTF-8"?>
      <xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.2" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd">
        <file original="Target/en.lproj/only_exclude.strings" source-language="en" datatype="plaintext">
          <body>
            <trans-unit id="excl">
              <source>does not matter</source>
            </trans-unit>
          </body>
        </file>
        <file original="Target/en.lproj/should_exclude_some.strings" source-language="en" datatype="plaintext">
          <body>
            <trans-unit id="exclude_trans_unit">
              <source>does not matter as well</source>
            </trans-unit>
            <trans-unit id="should_keep">
              <source>should keep</source>
            </trans-unit>
          </body>
        </file>
      </xliff>
      eos
      export_file = StringIO.new

      allow(File).to receive(:exist?).and_return(false)
      allow(Xlocalize::Helper).to receive(:xcode_at_least?).and_return(true)
      allow(Kernel).to receive(:system).with('xcodebuild -exportLocalizations -localizationPath ./ -project Project.xcodeproj')
      allow(File).to receive(:open).with('en.xliff').and_return(xliff)
      allow(File).to receive(:open).with('en.xliff', 'w').and_yield(export_file)
      Xlocalize::Executor.new.export_master(nil, 'Project.xcodeproj', ['Target'], '##', 'en', ['exclude_trans_unit', 'excl'])
      
      files = Nokogiri::XML(export_file.string).xpath("//xmlns:file").map { |f| f['original'] }
      trans_units = Nokogiri::XML(export_file.string).xpath("//xmlns:trans-unit").map { |node| node['id'] }
      expect(files).to eq(['Target/en.lproj/should_exclude_some.strings'])
      expect(trans_units).to eq(['should_keep'])
    end

    describe 'with WTI setup' do
      class WebtranslateItMock
        attr_reader :push_xliff_file
        attr_reader :push_plurals_file
        def push_master(file, plurals_file)
          @push_xliff_file = file
          @push_plurals_file = plurals_file
        end
        def pull(locale)
          { 'xliff' => Nokogiri::XML(open("en.xliff")).to_xml }
        end
      end

      wti = WebtranslateItMock.new
      fixture_path = 'spec/fixtures/ImportExportExample/'
      Xlocalize::Executor.new.export_master(wti, fixture_path << '/ImportExportExample.xcodeproj', ['ImportExportExample'], '##', 'en')

      it 'should create a YAML file for plurals in project' do
        plurals_yml = YAML.load_file('en.xliff_plurals.yml')
        expected_yml = {
          'en' => {
            'ImportExportExample/en.lproj/and_plurals.stringsdict' => {
              'users_count' => {
                'one' => '%d user',
                'other' => '%d users'
              }
            }
          }
        }
        expect(plurals_yml.to_a).to eq(expected_yml.to_a)
      end

      it 'should pass correct xliff file for upload' do
        expect(wti.push_xliff_file.path).to eq(File.open('en.xliff', 'r') { |f| f.path })
      end

      it 'should pass correct plurals file for upload' do
        expect(wti.push_plurals_file.path).to eq(File.open('en.xliff_plurals.yml', 'r') { |f| f.path })
      end

      it 'should have plurals filtered from xliff file' do
        doc = Nokogiri::XML(open("en.xliff"))
        trans_units = doc.xpath("//xmlns:trans-unit").map { |node| node['id'] }
        expect(trans_units.include? 'users_count').to eq(false)
      end
    end
  end
end
