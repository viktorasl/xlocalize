require 'spec_helper'
require 'fileutils'

class WebtranslateItMock
	attr_reader :push_xliff_file
	attr_reader :push_plurals_file
	def push_master(file, plurals_file)
		@push_xliff_file = file
		@push_plurals_file = plurals_file
	end
end

describe Xlocalize::Executor do
	describe '#export_master' do
		fixture_path = 'spec/fixtures/ImportExportExample/'

		wti = WebtranslateItMock.new
		Xlocalize::Executor.new.export_master(wti, fixture_path << '/ImportExportExample.xcodeproj', 'ImportExportExample', '##', 'en')

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
			begin
				f = File.open('en.xliff', 'r')
				expect(wti.push_xliff_file.path).to eq(f.path)
			ensure
				f.close unless f.nil?
			end
		end

		it 'should pass correct plurals file for upload' do
			begin
				f = File.open('en.xliff_plurals.yml', 'r')
				expect(wti.push_plurals_file.path).to eq(f.path)
			ensure
				f.close unless f.nil?
			end
		end
	end
end
