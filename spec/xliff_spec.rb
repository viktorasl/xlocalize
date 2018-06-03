require 'nokogiri'
require 'xlocalize/xliff'

describe Nokogiri::XML::Document do
  it 'filters files that are not part of specified target' do
    xliff = <<-eos
    <?xml version="1.0" encoding="UTF-8"?>
    <xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.2" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd">
      <file original="ImportExportExample/en.lproj/singles.strings" source-language="en" datatype="plaintext"></file>
      <file original="ImportExportExampleTests/en.lproj/and_plurals.strings" source-language="en" datatype="plaintext"></file>
      <file original="ImportExportExampleTests/en.lproj/singles.strings" source-language="en" datatype="plaintext"></file>
      <file original="ImportExportExample/en.lproj/and_plurals.strings" source-language="en" datatype="plaintext"></file>
    </xliff>
    eos
    doc = Nokogiri::XML(xliff)
    doc.filter_not_target_files(["ImportExportExample"])
    expected = ["ImportExportExample/en.lproj/singles.strings", "ImportExportExample/en.lproj/and_plurals.strings"]
    expect(doc.xpath("//xmlns:file").map { |f| f["original"] }).to eq(expected)
  end

  it 'filters files that does not contain any trans-unit' do
    xliff = <<-eos
    <?xml version="1.0" encoding="UTF-8"?>
    <xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.2" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd">
      <file original="ImportExportExample/en.lproj/singles.strings" source-language="en" datatype="plaintext">
        <body>
        </body>
      </file>
      <file original="ImportExportExample/en.lproj/and_plurals.strings" source-language="en" datatype="plaintext">
        <body>
          <trans-unit id="valid1"></trans-unit>
        </body>
      </file>
      <file original="ImportExportExample/en.lproj/other_file.strings" source-language="en" datatype="plaintext">
        <body>
          <trans-unit id="valid2"></trans-unit>
        </body>
      </file>
      <file original="ImportExportExample/en.lproj/empty_file.strings" source-language="en" datatype="plaintext">
        <body>
        </body>
      </file>
    </xliff>
    eos
    doc = Nokogiri::XML(xliff)
    doc.filter_empty_files()
    expected = ["ImportExportExample/en.lproj/and_plurals.strings", "ImportExportExample/en.lproj/other_file.strings"]
    expect(doc.xpath("//xmlns:file").map { |f| f["original"] }).to eq(expected)
  end

  it 'filters trans-units which sources do not include exclusive prefix' do
    xliff = <<-eos
    <?xml version="1.0" encoding="UTF-8"?>
    <xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.2" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd">
      <file original="ImportExportExample/en.lproj/and_plurals.strings" source-language="en" datatype="plaintext">
        <header>
          <tool tool-id="com.apple.dt.xcode" tool-name="Xcode" tool-version="8.1" build-num="8B62"/>
        </header>
        <body>
          <trans-unit id="valid1">
            <source>Valid 1</source>
          </trans-unit>
          <trans-unit id="valid2">
            <source>Valid 2</source>
          </trans-unit>
          <trans-unit id="notvalid1">
            <source>##Not Valid 1</source>
          </trans-unit>
          <trans-unit id="notvalid2">
            <source>## Not Valid 2</source>
          </trans-unit>
          <trans-unit id="valid3">
            <source>Valid 3</source>
          </trans-unit>
          <trans-unit id="notvalid3">
            <source>##Not Valid 3</source>
          </trans-unit>
        </body>
      </file>
    </xliff>
    eos
    doc = Nokogiri::XML(xliff)
    doc.filter_trans_units("##")
    expect(doc.xpath("//xmlns:trans-unit").map { |trans_unit| trans_unit["id"] }).to eq(["valid1", "valid2", "valid3"])
  end

  it 'filters strings files that match storyboard or xib name' do
    xliff = <<-eos
    <?xml version="1.0" encoding="UTF-8"?>
    <xliff xmlns="urn:oasis:names:tc:xliff:document:1.2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.2" xsi:schemaLocation="urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/os/xliff-core-1.2-strict.xsd">
      <file original="path/to/translations/en.lproj/view.strings" datatype="plaintext" source-language="en"></file>
      <file original="path/to/xibs/en.lproj/view.xib" datatype="plaintext" source-language="en"></file>
      <file original="path/to/translations/en.lproj/story.strings" datatype="plaintext" source-language="en"></file>
      <file original="path/to/storyboards/en.lproj/story.storyboard" datatype="plaintext" source-language="en"></file>
      <file original="path/to/translations/en.lproj/only_strings.strings" datatype="plaintext" source-language="en"></file>
    </xliff>
    eos
    doc = Nokogiri::XML(xliff)
    doc.filter_duplicate_storyboard_xib_files
    expected = [
      "path/to/xibs/en.lproj/view.xib",
      "path/to/storyboards/en.lproj/story.storyboard",
      "path/to/translations/en.lproj/only_strings.strings"
    ]
    expect(doc.xpath("//xmlns:file").map { |f| f["original"] }).to eq(expected)
  end

  it 'unescapes trans units if they are escaped' do
    doc = Nokogiri::XML(File.open('spec/fixtures/xliff_quotes.xliff'))
    doc.unescape
    expect(doc.xpath('//xmlns:source').to_xml).to eq('<source>Some text which "has" quotes</source><source>Usual text</source>')
  end
end
