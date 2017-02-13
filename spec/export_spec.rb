require 'spec_helper'

describe Xlocalize::Executor do
	describe '#export_master' do
		fixture_path = 'spec/fixtures/ImportExportExample/'
		Xlocalize::Executor.new.export_master(nil, fixture_path << '/ImportExportExample.xcodeproj', 'ImportExportExample', '##', 'en')
		it 'should create a YAML file for plurals in project' do
			plurals_yml = YAML.load_file('en.xliff_plurals.yml')
			expected_yml = {
				'spec/fixtures/ImportExportExample/ImportExportExample/en.lproj/and_plurals.stringsdict' => {
					'one' => '%d user',
					'other' => '%d users'
				}
			}
			expect(plurals_yml.to_a).to eq(expected_yml.to_a)
		end
	end
end
